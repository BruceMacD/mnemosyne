import openai
import os
from pymilvus import connections, utility, FieldSchema, Collection, CollectionSchema, DataType
from tqdm import tqdm

# HOST: The Milvus host address
# PORT: The Milvus port number
# DIMENSION: The dimension of the embeddings
# OPENAI_ENGINE: Which embedding model to use
# openai.api_key: OpenAI account key
# INDEX_PARAM: The index settings to use for the collection
# QUERY_PARAM: The search parameters to use
HOST = 'localhost'
PORT = 19530
COLLECTION_NAME = 'book_search'
DIMENSION = 1536
OPENAI_ENGINE = 'text-embedding-ada-002'
openai.api_key = os.getenv('OPENAI_API_KEY')

INDEX_PARAM = {
    'metric_type': 'L2',
    'index_type': "HNSW",
    'params': {'M': 8, 'efConstruction': 64}
}

QUERY_PARAM = {
    "metric_type": "L2",
    "params": {"ef": 64},
}

# Simple function that converts the texts to embeddings


def embed(texts):
    embeddings = openai.Embedding.create(
        input=texts,
        engine=OPENAI_ENGINE
    )
    return [x['embedding'] for x in embeddings['data']]


def query(queries, top_k=3):
    if type(queries) != list:
        queries = [queries]
    res = collection.search(embed(queries), anns_field='embedding',
                            param=QUERY_PARAM, limit=top_k, output_fields=['query'])
    for i, hit in enumerate(res):
        print('query:', queries[i])
        for ii, hits in enumerate(hit):
            print(hits.entity.get('query'))


# Connect to Milvus Database
connections.connect(host=HOST, port=PORT)

# Remove collection if it already exists
if utility.has_collection(COLLECTION_NAME):
    utility.drop_collection(COLLECTION_NAME)

fields = [
    FieldSchema(name='id', dtype=DataType.INT64,
                is_primary=True, auto_id=True),
    FieldSchema(name='query', dtype=DataType.VARCHAR, max_length=64000),
    FieldSchema(name='embedding', dtype=DataType.FLOAT_VECTOR, dim=DIMENSION)
]
schema = CollectionSchema(fields=fields)
collection = Collection(name=COLLECTION_NAME, schema=schema)

# Create the index on the collection and load it.
collection.create_index(field_name="embedding", index_params=INDEX_PARAM)
collection.load()

data = [
    [],  # query
]

# Embed and insert in batches
data[0].append("my name is bob")
data.append(embed(data[0]))
collection.insert(data)
data = [[]]

data[0].append("i like turtles")
data.append(embed(data[0]))
collection.insert(data)
data = [[]]

data[0].append("i like tea")
data.append(embed(data[0]))
collection.insert(data)
data = [[]]

query("who is this?")
