# Stern GUI Docker image

Docker image to expose:
- stern gui built with Angular 17, tailwind and daisyui [stern-gui](https://github.com/nicholasricci/stern-gui)
- stern daemon built with python3 and flask [stern-daemon](https://github.com/nicholasricci/stern-daemon)

## Run docker image

To run docker image you can mount a volume to store the configurations managed by stern-daemon.
The container exposed port 80 for the stern-gui:

```bash
$ docker run --rm -i -t -p 80:80 -v ~/.stern-gui:/root/.stern-gui nicholasricci92/stern-gui:latest 
```