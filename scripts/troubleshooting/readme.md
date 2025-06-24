>[!NOTE]
> ## To display which services or ports are currently running on your Nextcloud AIO server,
>>you should use Docker commands to inspect your running containers and their published ports.
>>>Here’s how you can do it:

---

## **1. List All Running Docker Containers and Their Ports**

Run the following command in your terminal:

```bash
sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"
```

This will show you all running containers, their names, and the ports they expose or publish[1][2][3].

---

## **2. See Detailed Port Mapping for a Specific Container**

If you want more detailed information about how ports are mapped between the host and a specific container (for example, `nextcloud-aio-mastercontainer`), use:

```bash
sudo docker inspect --format '{{.Name}} {{range $p, $conf := .NetworkSettings.Ports}}{{if $conf}}{{$p}}->{{range $conf}}{{.HostIp}}:{{.HostPort}} {{end}}{{end}}{{end}}' $(sudo docker ps -q)
```

This will show you each container, its exposed ports, and how they are mapped to your host system[1][2].

---

## **3. Check Which Ports Are Listening on the Host**

To see which ports are actually listening on your host machine (regardless of Docker), run:

```bash
sudo ss -tulpn
```
or
```bash
sudo lsof -i -P -n | grep LISTEN
```

These commands will list all listening ports and the processes using them.

---

## **Summary Table**

| Command                                                                 | Purpose                                                                 |
|-------------------------------------------------------------------------|-------------------------------------------------------------------------|
| `sudo docker ps --format "table {{.ID}}\t{{.Names}}\t{{.Ports}}"`      | List running Docker containers and their ports                          |
| `sudo docker inspect --format ...` (see above)                          | Detailed port mapping between host and container                        |
| `sudo ss -tulpn` or `sudo lsof -i -P -n | grep LISTEN`                | List all listening ports and processes on the host                      |

---

**These commands will help you identify which services or ports are currently active and how they are mapped on your Nextcloud AIO server.**
