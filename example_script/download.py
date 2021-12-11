import argparse
import os
import sys
import io
import requests as rq
import contextlib as ctx
from tqdm import tqdm


class DownloadError(Exception):
    pass

def get_file(hostname, link, token=None):
    print(f"Download from {hostname}, link={link}")
    base_link = f"{hostname}/f.php?h={link}&a=1&d=1"
    ret = rq.get(base_link + "&x=0")
    if ret.status_code != 200:
        raise DownloadError(f"Status: {ret.status_code}, Textt: {ret.text}")

    try:
      filename = ret.headers['X-Jirafeau-Filename']
    except KeyError as e:
      raise DownloadError("Invalid protocol, missing header 'X-Jirafeau-Filename'")
    try:
      file_size = int(ret.headers['X-Jirafeau-Filesize'])
    except KeyError as e:
      raise DownloadError("Invalid protocol, missing header 'X-Jirafeau-Filesize'")
    print(f".. filename is {filename}, filesize is {file_size}")

    with tqdm(
        total=file_size,
        desc=f"Downloading {filename}",
        unit="B",
        unit_divisor=1024,
        unit_scale=True
    ) as pb, open(filename,mode="wb") as output:
        remaining = int(ret.headers['X-Jirafeau-Remaining'])
        current = 0
        while True: 
            buf = ret.content
            output.write(buf)
            pb.update(len(buf))
            current += len(buf)
            if current == file_size:
              break 
            ret = rq.get(f"{base_link}&x={current}")
            if ret.status_code != 200:
                raise DownloadError(ret.text)
            remaining = ret.headers['X-Jirafeau-Remaining']

key = None

hostname = "https://upload.aquila-consortium.org/Jirafeau2"

args = argparse.ArgumentParser()
args.add_argument("link", type=str)
args.add_argument("--url", type=str, default=None)

vals = args.parse_args()
if vals.url is not None:
  hostname = vals.url

try:
  get_file(hostname, vals.link) 
except DownloadError as e:
  print(e)
except Exception as e:
  print(type(e), e)
