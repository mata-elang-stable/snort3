# Snort3 Docker Image for Mata Elang

Snort v3 description

The image is already available at https://hub.docker.com/r/mfscy/snort-base


## Requirements
 - [Docker](https://docs.docker.com/engine/install) with buildx enabled

## How to build the image?
You can build the image simply by using the following command:
```bash
docker build -t snort3-base -f dockerfiles/debian.dockerfile .
```

## Usage
This is simple usage to check the Snort version
```bash
docker run --rm -it mfscy/snort-base:3 snort -v
```

