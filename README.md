# AEM Shell Tools

Command-line utilities for AEM instances. Content packaging, node creation, file upload, workflow management, active/inactive bundles stats.

## Scripts

| Script | Purpose |
|---|---|
| [`aem-cp-pkg.sh`](aem-cp-pkg.sh) | Create content package on source AEM instance, download, and install on target AEM instance |
| [`aem-mk-pkg.sh`](aem-mk-pkg.sh) | Create content package, and download to disk |
| [`aem-create-folder.sh`](aem-create-folder.sh) | Create an `nt:folder` node;  takes full URL of the new node, e.g. http://localhost:4502/content/newfolder |
| [`aem-create-node.sh`](aem-create-node.sh) | Create a node/page with given JCR properties |
| [`bundles.sh`](bundles.sh) | Print AEM bundle status, active/inactive count |
| [`aem_post_file.py`](aem_post_file.py) | Upload a file via the Sling POST servlet |
| [`wf.py`](wf.py) | List and kill workflow instances |

## Requirements

- `curl`
- `bash`
- `python3` with `requests` (for `aem_post_file.py` and `wf.py`)

Defaults: `http://localhost:4502`, user `admin`, password `admin`. Bash scripts honour env vars `AEM_HOST`, `AEM_USER`, `AEM_PASS`, etc. — see each script's section below. The `AEM_` prefix avoids collision with the shell's built-in `$USER`.

## [`aem-cp-pkg.sh`](aem-cp-pkg.sh)

Copies content from given JCR path from a source AEM to a target AEM via a content package.

```
./aem-cp-pkg.sh /content/we-retail/us/en
```

Defaults (override via env vars):

| Var | Default |
|---|---|
| `AEM_HOST` | `http://demo.netcentric.biz:4502` (source) |
| `AEM_USER` | `admin` |
| `AEM_PASS` | `secret42` |
| `AEM_HOST2` | `http://localhost:4502` (target) |
| `AEM_USER2` | `admin` |
| `AEM_PASS2` | `admin` |
| `GRP_NAME` | `ncpkg` |
| `PKG_NAME` | `ncdump` |

Example:

```
AEM_HOST=http://src.example.com:4502 AEM_PASS=sekret \
AEM_HOST2=http://tgt.example.com:4502 AEM_PASS2=other \
  ./aem-cp-pkg.sh /content/we-retail/us/en
```

Concurrent runs with the same `GRP_NAME`/`PKG_NAME` will collide.

For multi-path filters, see the commented JSON block in the file.

After install, script will offer to reveal the zip in Finder and open the path in the target CRXDE.

## [`aem-mk-pkg.sh`](aem-mk-pkg.sh) 

Creates a content package on an AEM instance and downloads it to current folder.

```
./aem-mk-pkg.sh /content/mam/offers/test
```

Output: `ncpkg-ncdump.zip` in the current directory.

Defaults (override via env vars):

| Var | Default |
|---|---|
| `AEM_HOST` | `http://localhost:4502` |
| `AEM_USER` | `admin` |
| `AEM_PASS` | `admin` |
| `GRP_NAME` | `ncpkg` |
| `PKG_NAME` | `ncdump` |

Example:

```
AEM_HOST=http://localhost:1984 AEM_USER=customuser AEM_PASS=secret42 PKG_NAME=my-pkg \
  ./aem-mk-pkg.sh /content/mam/offers/test
```

## [`aem-create-folder.sh`](aem-create-folder.sh)

Creates an `nt:folder` node. Intermediary folders created automatically.

```
./aem-create-folder.sh http://localhost:4502/apps/weretail/components/content/articleslist/newnode
```

Defaults (override via env vars): `AEM_USER=admin`, `AEM_PASS=admin`.

```
AEM_PASS=sekret ./aem-create-folder.sh http://localhost:4502/content/newfolder
```

Fetches the CSRF token before posting.

## [`aem-create-node.sh`](aem-create-node.sh) 

Creates a node with desired properties. Pass the URL as the first argument, then any `curl -F` pairs.

```
./aem-create-node.sh http://localhost:4502/content/newpage \
  -F jcr:primaryType=cq:Page \
  -F jcr:content/jcr:primaryType=cq:PageContent \
  -F jcr:content/sling:resourceType=mam/ma/pages/structure \
  -F jcr:content/jcr:title=mynewpage
```

Missing intermediary nodes are created as `sling:OrderedFolder`. CSRF token is fetched automatically.

Defaults (override via env vars): `AEM_USER=admin`, `AEM_PASS=admin`.

Property values with spaces are not supported — arguments are word-split.

## [`bundles.sh`](bundles.sh)

Prints a one-line bundle status from AEM's Felix console.

```
./bundles.sh
```

Host and credentials hardcoded in the URL.

## [`aem_post_file.py`](aem_post_file.py)

Uploads a file to AEM via the Sling POST servlet.

```
./aem_post_file.py http://localhost:4502/content/dam/my-folder \
  --import-from ./asset.jpg
```

Arguments:

- `url` — target AEM URL (positional, required)
- `-i / --import-from` — local file path (required)
- `-n / --node-name` — node name in AEM (default: file basename)
- `-u / --user` — default `admin`
- `-p / --password` — default `admin`
- `-d / --debug` — print response body


## [`wf.py`](wf.py)

Lists AEM workflow instances. Optionally kills them.

```
# List only
./wf.py http://localhost:4502 -w

# Kill STALE instances, up to 1,000,000 records
./wf.py http://localhost:4502 -w -k -l 1000000

# Kill all instances matching 'smart tag', including RUNNING
./wf.py http://localhost:4502 -w -f 'smart tag' -kk
```

Arguments:

- `host` — AEM URL (positional, default `http://localhost:4502`)
- `-w / --wide` — include model name in output
- `-f / --filter` — model name substring, case-insensitive
- `-k / --kill` — kill STALE instances
- `-kk / --kill9` — kill all matched instances including RUNNING
- `-l / --limit` — max records to fetch (default 1000)
- `-v / --verbose` — print raw JSON at end
- `-d / --debug` — HTTP debug output
- `-u / --user`, `-p / --password` — default `admin:admin`




