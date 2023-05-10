# Mnemosyne
Mnemosyne is a long term memory for ChatGPT.
<div align="center">
<img width="409" alt="Screenshot 2023-05-08 at 10 49 46 PM" src="https://user-images.githubusercontent.com/5853428/237005760-41195229-41b3-4d23-b8ec-426591067c82.png">
<img width="410" alt="Screenshot 2023-05-08 at 10 48 55 PM" src="https://user-images.githubusercontent.com/5853428/237005763-1065f5c7-24e7-4aeb-8bd4-dcfb8e73de75.png">
 </div>


# How It Works
<div align="center">
<a href="https://user-images.githubusercontent.com/5853428/237001597-bcdd4313-03c7-47a4-971e-d1afb2d78d2b.png"><img src="https://user-images.githubusercontent.com/5853428/237001597-bcdd4313-03c7-47a4-971e-d1afb2d78d2b.png" width="200"></a>
</div>
Mnemosyne operates by storing all of its conversations in a local vector database known as Milvus. To create a contextual understanding, it utilizes the OpenAI API to extract embeddings from these conversations. Stored within Milvus, these embeddings enable Mnemosyne to retrieve past messages that bear similarity to the current context. The system then improves the input query by adding context before forwarding it to the ChatGPT API.

# Running

## Install Dependencies

```
pip3 install -r setup/requirements.txt
```

## Run Milvus

```
docker-compose -f ./setup/docker-compose.yaml up -d
```
