# freenet-wikipedia

This is a set of tools to convert a ZIM archive containing a Wikipedia dump into a format that can be inserted into Freenet.

Requires `extract_zim` from [zim](https://github.com/dignifiedquire/zim) and a [Kiwix ZIM archive](http://wiki.kiwix.org/wiki/Content_in_all_languages).

Usage:

    $ wget http://download.kiwix.org/zim/wikipedia_pih_all.zim
    $ extract_zim wikipedia_pih_all.zim
    $ ./convert.sh
    $ ./putdir.sh result my-mirror index.html

At completion of the insert this will output a list of keys. the `uri` key is the one that can be shared for others to retrieve the insert. The `uskinsert` key can be used to insert an updated version of the site:

    $ ./putdir.sh result my-mirror index.html <uskinsert key>

The `convert.sh` script was a quick 'proof of concept' hack and could be improved in many ways. I welcome patches and better ways of doing things.

More information available [in my blog post about mirroring wikipedia](https://bluishcoder.co.nz/2017/05/16/distributed-wikipedia-mirrors-in-freenet.html).
