# scheme-swl-docker

## 1. Install Docker

Install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/).

## 2. Start the container

Open a terminal in this directory and run:

```sh
docker compose up --build -d
```

The first build may take several minutes.

## 3. Open Scheme

Visit <http://localhost:6000/> in a web browser. The SWL editor and
interaction window will open automatically.

Example programs are available in the SWL editor at:

- `/workspace/examples/hello.ss`
- `/workspace/examples/gui-demo.ss`

## 4. Stop the container

Run:

```sh
docker compose down
```
