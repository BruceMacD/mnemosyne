//
//  Milvus.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-04-30.
//

import Foundation
import PythonKit
import OpenAI

let sys = Python.import("sys")
let pymilvus = Python.import("pymilvus")
let tqdm = Python.import("tqdm.tqdm")
let np = Python.import("numpy")

struct SearchResult {
    let queryResult: PythonObject

    func count() -> Int {
        return Int(queryResult.__len__())!
    }

    func item(at index: Int) -> Hits {
        return Hits(res: queryResult.__getitem__(index))
    }
}

struct Hits {
    let res: PythonObject

    func count() -> Int {
        return Int(res.__len__())!
    }

    func item(at index: Int) -> PythonObject {
        return res.__getitem__(index)
    }
}

public class MilvusClient {
    let INDEX_PARAM: PythonObject = [
        "metric_type": "L2",
        "index_type": "HNSW",
        "params": ["M": 8, "efConstruction": 64]
    ]

    let QUERY_PARAM: PythonObject = [
        "metric_type": "L2",
        "params": ["ef": 64]
    ]
    
    var host: String
    var collectionName: String
    var port: Int
    var dimension: Int
    var collection: PythonObject
    
    init(host: String, collectionName: String, port: Int, dimension: Int) {
        print(sys.path)
        self.host = host
        self.collectionName = collectionName
        self.port = port
        self.dimension = dimension
        
        // Connect to Milvus Database
        pymilvus.connections.connect(host: self.host, port: self.port)
        
        let fields: PythonObject = [
            pymilvus.FieldSchema(name: "id", dtype: pymilvus.DataType.INT64, is_primary: true, auto_id: true),
            pymilvus.FieldSchema(name: "query", dtype: pymilvus.DataType.VARCHAR, max_length: 64000),
            pymilvus.FieldSchema(name: "embedding", dtype: pymilvus.DataType.FLOAT_VECTOR, dim: self.dimension)
        ]
        let schema = pymilvus.CollectionSchema(fields: fields)
        collection = pymilvus.Collection(name: self.collectionName, schema: schema)
        
        if !(Bool(pymilvus.utility.has_collection(self.collectionName)) ?? false) {
            // index does not exist yet, create it now
            collection.create_index(field_name: "embedding", index_params: INDEX_PARAM)
        }

        collection.load()
    }
    
    public func insert(query: String, embedding: EmbeddingsResult) {
        var data: [[PythonObject]] = [
            [],  // query
            [],  // embedding
        ]
        
        data[0].append(PythonObject(query))
        data[1].append(embeddedData(embedding: embedding))
        
        collection.insert(data)
    }

    func query(embedding: EmbeddingsResult, topK: Int = 3) -> [String] {
        let embeddingData = embeddedData(embedding: embedding)
        let pythonEmbeddingDataList = Python.list(embeddingData)
        let pythonEmbeddingData = PythonObject([pythonEmbeddingDataList])
        
        let resp = collection.search(pythonEmbeddingData, anns_field: "embedding", param: QUERY_PARAM, limit: topK, output_fields: ["query"])
        let searchRes = SearchResult(queryResult: resp)
        
        var result = [String]()
        result.reserveCapacity(topK)
        for i in 0..<searchRes.count() {
            let hit = searchRes.item(at: i)
            for ii in 0..<hit.count() {
                let hits = hit.item(at: ii)
                let q = hits.entity.get("query")
                if let queryString = String(q) {
                    result.append(queryString)
                }
            }
        }
        return result
    }
    
    func embeddedData(embedding: EmbeddingsResult) -> PythonObject {
        // Convert the embedding data to a numpy float32 array and create a PythonObject
        let pythonEmbeddingData = np.array(embedding.data[0].embedding.map { Float($0) }, dtype: np.float32)
        return PythonObject(pythonEmbeddingData.tolist())
    }
}
