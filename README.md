# scheme-swl-docker

## 1. Install Docker

Install and start [Docker Desktop](https://www.docker.com/products/docker-desktop/).

## 2. Build and start the container

Open a terminal in this project directory (the folder containing
`compose.yaml`) and run:

```sh
docker compose up --build -d
```

The first build may take several minutes. The `-d` option keeps the container
running in the background.

After the image has been built, start the container again with:

```sh
docker compose up -d
```

## 3. Open Scheme

Visit <http://127.0.0.1:6080/> in a web browser. The SWL desktop will load in
the browser.

Example programs are available in the SWL editor at:

- `/workspace/examples/hello.ss`
- `/workspace/examples/gui-demo.ss`

## 4. Run a sample program

Click after the `>` prompt in the Scheme window, type this command, and press
Enter:

```scheme
(load "/workspace/examples/hello.ss")
```

The output should include `factorial(6) = 720`.

To run the GUI example, enter:

```scheme
(load "/workspace/examples/gui-demo.ss")
```

A window titled `Scheme/SWL GUI Demo` should appear.

## 5. View running containers

From the project directory, run:

```sh
docker compose ps
```

The status should say `Up` and `healthy`.

To view every running Docker container, run `docker ps`.

## 6. Stop the container

Stop it while keeping the container available for later:

```sh
docker compose stop
```

Start it again with `docker compose up -d`.

To stop and remove the container and its Docker network, run:

```sh
docker compose down
```
