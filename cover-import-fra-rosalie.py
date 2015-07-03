from __future__ import print_function
import requests
from bs4 import BeautifulSoup
import re
from PIL import Image
from io import BytesIO

baseUrl = 'http://ub-prod01-imgs.uio.no/42/covers/'
response = requests.get(baseUrl)
page = BeautifulSoup(response.content)

links = [a.attrs['href'] for a in page.find_all('a')]
links = [href.replace('.jpg','') for href in links if re.search('.jpg', href)]


def get_image_size(url):
    data = requests.get(url).content
    im = Image.open(BytesIO(data))
    return im.size


for bsid in links:
	print(bsid)
	url = '{}{}.jpg'.format(baseUrl, bsid)
	dim = get_image_size(url)

	res = requests.get('http://colligator.biblionaut.net/api/documents?q=bibsys_id:' + bsid)
	docs = res.json()['documents']
	if len(docs) != 1:
		print(" - Not found!")
		continue

	doc = docs[0]
	if doc['cover'] is not None:
		w = doc['cover']['cached']['width']
		h = doc['cover']['cached']['height']
		print('Existing: %d x %d  - New: %d x %d' % (w, h, dim[0], dim[1]))

		if w > dim[0]:
			print(" - Ignoring since %s is larger" % (url))
			continue

	response = requests.post('http://colligator.biblionaut.net/api/documents/{}/cover'.format(doc['id']), {'url': url})
