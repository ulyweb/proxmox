Remove all **Docker networks** (except the default ones like `bridge`, `host`, and `none`) using a single command in the terminal. Here's how you can do it:

```bash
docker network prune -f
```

### Explanation:
- `docker network prune`: Removes all unused networks.
- `-f` or `--force`: Skips the confirmation prompt.

However, if you want to **remove all networks including active ones** (which Docker doesn't allow directly if containers are using them), you can use a more forceful approach:

```bash
docker network ls -q | xargs -r docker network rm
```

### Important Notes:
- This command attempts to remove **all networks**, including those in use.
- If a network is in use by a container, Docker will return an error for that network.
- You can stop and remove all containers first if you want to ensure all networks can be removed:

```bash
docker container stop $(docker container ls -q)
docker container rm $(docker container ls -q -a)
docker network ls -q | xargs -r docker network rm
```

