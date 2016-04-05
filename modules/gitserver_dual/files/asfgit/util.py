import os


def decode(val):
    assert isinstance(val, str)
    return val.decode("utf-8", "replace")


def encode(val):
    assert isinstance(val, unicode)
    return val.encode("utf-8", "replace")


def environ(name, null=False):
    ret = os.environ.get(name)
    if ret is None and not null:
        raise KeyError(name)
    elif ret is None:
        return None
    return decode(ret)


def abort(mesg):
    assert isinstance(mesg, unicode), "String encoding error."
    print mesg.encode("utf-8")
    exit(1)
