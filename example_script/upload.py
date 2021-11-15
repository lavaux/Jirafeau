import argparse
import os
import sys
import io
import requests as rq
import contextlib as ctx
from tqdm import tqdm

hostname = "https://upload.aquila-consortium.org/Jirafeau2"
passwd = ""
BUFFER_SIZE = 10 * 1024 * 1024


class UploadError(IOError):
    pass


def upload_file(file_like, file_size=None, time="month", filename="data.dat", key=None, token=None):

    data = {"time": time, "upload_password": passwd, "filename": filename}
    if not key is None:
        data["key"] = key

    if not token is None:
      data["token"] = token

    ret = rq.post(f"{hostname}/script.php?init_async", data=data)
    if ret.text.find("Error") != -1:
        raise UploadError(ret.text)

    href, code = ret.text.split("\n")
    data["ref"] = href

    with tqdm(
        total=file_size,
        desc=f"Uploading {filename}",
        unit="B",
        unit_divisor=1024,
        unit_scale=True
    ) as pb:
        while True:
            data["code"] = code
            buf = file_like.read(BUFFER_SIZE)
            if len(buf) == 0:
                break
            pb.update(len(buf))

            file_data = {"data": io.BytesIO(buf)}

            ret = rq.post(
                f"{hostname}/script.php?push_async", data=data, files=file_data
            )
            if ret.text.find("Error") != -1:
                raise UploadError(ret.text)
            code = ret.text.split("\n")[0]

    ret = rq.post(f"{hostname}/script.php?end_async", data=data)
    if ret.text.find("Error") != -1:
        raise UploadError(ret.text)
    hlink, del_link, crypt_key = ret.text.split("\n")

    if len(crypt_key) != 0:
        k_str = "k=" + crypt_key
    else:
        k_str = ""

    return {
        "download": f"{hostname}/f.php?h={hlink}{k_str}",
        "direct": f"{hostname}/f.php?h={hlink}{k_str}&d=1",
        "delete": f"{hostname}/f.php?h={hlink}{k_str}&d={del_link}",
    }


key = None

args = argparse.ArgumentParser()
args.add_argument("filename", type=str)
args.add_argument("--token", type=str, default=None)

vals = args.parse_args()
fname = vals.filename
with open(fname, mode="rb") as in_f:
    file_size = os.path.getsize(fname)
    detail = upload_file(in_f, file_size=file_size, filename=os.path.basename(fname), token=vals.token)

print(f"Download link is {detail['download']}")
print(f"Direct download link is {detail['direct']}")
print(f"Delete link is {detail['delete']}")
