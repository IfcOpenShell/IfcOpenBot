import io
import sys
import os
import glob
import json

# pip install github3.py
import github3
# pip install boto3
import boto3

s3 = boto3.client('s3',
    region_name           = os.environ.get('AWS_UPLOAD_REGION'),
    aws_access_key_id     = os.environ.get('AWS_UPLOAD_ACCESS_KEY_ID'),
    aws_secret_access_key = os.environ.get('AWS_UPLOAD_SECRET_ACCESS_KEY'),
)

def upload(s3, filter=None):
    for fn in glob.glob("output/*.zip"):
        bfn = os.path.basename(fn)
        if "-old-" in fn: continue
        if filter is not None:
            if filter not in bfn: continue
        # print("uploading", bfn)
        s3.upload_file(fn, "ifcopenshell-builds", bfn)
        os.rename(fn, os.path.join("uploaded", bfn))
        yield bfn, "https://s3.amazonaws.com/" + os.environ.get('AWS_UPLOAD_BUCKET') + "/" + bfn
        
def getpkg(tup):
    def fix310(s):
        if s == "31":
            return "310"
        return s
    if tup[0] == "ifcblender": return "Blender py%s" % fix310(tup[2])
    elif tup[1] == "python": return "Python %s" % fix310(tup[2])
    else: return tup[0]
    
def getos(incl_bit=True):
    def getos_(tup):
        f = os.path.splitext(tup[-1])[0]
        a,b = f[:-2], f[-2:]
        o = {'macos': 'macOS', 'osx': 'macOS', 'osxm1': 'macOS M1', 'macosm1': 'macOS M1'}.get(a.lower(), a.title())
        if incl_bit:
            return "{} {}".format(o, b)
        else:
            return o
    return getos_
    
def getbit(tup):
    f = os.path.splitext(tup[-1])[0]
    return f[-2:]
        
def table(filepairs):
    tups = list(map(lambda t: t[0].split('-'), filepairs))
    pkgs, oses, bits = (list(map(fn, tups)) for fn in (getpkg, getos(incl_bit=False), getbit))
    rows, cols = (sorted(set(li)) for li in (pkgs, oses))
    cells = [[" "] + cols, ["---"] * (len(cols) + 1)] + [([r] + [" "] * len(cols)) for r in rows]
    for (fn, url), r, c, b in zip(filepairs, pkgs, oses, bits):
        val = ["[{bit}bit]({url})".format(bit=b, url=url)]
        if len(cells[rows.index(r) + 2][cols.index(c) + 1]) > 1:
            val.append( cells[rows.index(r) + 2][cols.index(c) + 1] )
        cells[rows.index(r) + 2][cols.index(c) + 1] = " / ".join(sorted(val))
    return "\n".join(map(lambda row: "|{}|".format("|".join(cs for cs in row)), cells))
    
def getdicts(filepairs):
    tups = list(map(lambda t: t[0].split('-'), filepairs))
    pkgs, oses = (list(map(fn, tups)) for fn in (getpkg, getos()))
    rows, cols = (sorted(set(li)) for li in (pkgs, oses))
    def _():
        for (fn, url), r, c in zip(filepairs, pkgs, oses):
            yield {'product': r, 'platform': c, 'filename': fn, 'url': url} 
    return list(_())
    
GITHUB_USERNAME = os.environ.get('GIT_USER')
GITHUB_TOKEN = os.environ.get('GIT_PASS')

REPO = (GITHUB_USERNAME, 'IfcOpenShell')

def get_contributors():
    import os
    import requests

    endpoint = "https://api.opencollective.com/graphql/v2"

    query = """query project($slug: String) {
      project(slug: $slug) {
        name
        slug
        parentAccount {
          slug
        }
        members(role: BACKER) {
          totalCount
          nodes {
            account {
              name
            }
          }
        }
      }
    }"""

    D = requests.post(endpoint, json={'query': query, 'variables': {'slug': 'apple-m1-build-server'}}, headers={"Api-Key": os.environ["OPENCOLLECTIVE_APIKEY"]}).json()

    return "Apple M1 builds thanks to: " + ", ".join([n['account']['name'] for n in D['data']['project']['members']['nodes']]) + \
    "\n\n Support us on [Open Collective](https://opencollective.com/opensourcebim)"

    
g = github3.login(GITHUB_USERNAME, GITHUB_TOKEN)
repository = g.repository(*REPO)
comment_body = """Hi,

I've created the following builds for your {item}:

{builds}

{thanks}

Kind regards,
IfcOpenBot
"""
    
def main(sha):
    filepairs = list(upload(s3, sha[0:7]))
    builds = table(filepairs)

    try:
        thanks = get_contributors()
    except:
        import traceback
        traceback.print_exc()
        thanks = ""
        
    body=comment_body.format(
        item="commit",
        builds=builds,
        thanks=thanks
    )
    repository.create_comment(sha=sha, body=body)
    
    jsn = io.BytesIO()
    jsn.write(json.dumps(getdicts(filepairs)).encode('ascii'))
    jsn.seek(0)
    branch_name = os.environ.get("branch", "v0.6.0")
    s3.upload_fileobj(jsn, os.environ.get('AWS_UPLOAD_BUCKET'), "{}.json".format(branch_name))

if __name__ == "__main__":
    main(sys.argv[1])
