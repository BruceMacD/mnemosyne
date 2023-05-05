//
//  Milvus.swift
//  mnemosyne
//
//  Created by Bruce MacDonald on 2023-04-30.
//

import Foundation
import PythonKit

let sys = Python.import("sys")
let pymilvus = Python.import("pymilvus")
let tqdm = Python.import("tqdm.tqdm")

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

        // Remove collection if it already exists
        if Bool(pymilvus.utility.has_collection(self.collectionName)) ?? false {
            pymilvus.utility.drop_collection(self.collectionName)
        }
        
        let fields: PythonObject = [
            pymilvus.FieldSchema(name: "id", dtype: pymilvus.DataType.INT64, is_primary: true, auto_id: true),
            pymilvus.FieldSchema(name: "query", dtype: pymilvus.DataType.VARCHAR, max_length: 64000),
            pymilvus.FieldSchema(name: "embedding", dtype: pymilvus.DataType.FLOAT_VECTOR, dim: self.dimension)
        ]
        let schema = pymilvus.CollectionSchema(fields: fields)
        collection = pymilvus.Collection(name: self.collectionName, schema: schema)

        // Create the index on the collection and load it.
        collection.create_index(field_name: "embedding", index_params: INDEX_PARAM)
        collection.load()
    }
    
    public func insert(data: PythonConvertible) {
        collection.insert(data)
    }
}
