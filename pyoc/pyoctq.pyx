cimport pyoctq

from cpython.version cimport PY_MAJOR_VERSION
from numpy cimport ndarray as arr
from numpy import array
ctypedef unsigned char char_type
cdef public gtp_equilibrium_data *ceq
cdef extern int c_ntup
cdef extern char *c_cnam[]
cdef extern int c_nel

cdef char* _chars(s):
    if isinstance(s, unicode):
        s = (<unicode>s).encode('utf8')
    return s 

cdef unicode _text(s):
    if type(s) is unicode:
        return <unicode>s
    elif PY_MAJOR_VERSION < 3 and isinstance(s, bytes):
        return (<bytes>s).decode('ascii')
    elif isinstance(s,unicode):
        return unicode(s)
    else:
        raise TypeError("Could not convert to unicode.")

def tqini(int n):
    #cdef gtp_equilibrium_data *ceq
    c_tqini(n, <void**> &ceq)

def tqrfil(s):
    cdef char *filename = _chars(s)
    c_tqrfil(filename,<void**> &ceq)

def tqgpn(int i):
    cdef char *cphname=_chars("")
    c_tqgpn(i, cphname,<void**> &ceq)
    cdef bytes pyname = cphname
    return pyname

def tqsetc(cond, int n1, int n2, double tp):
    cdef int cnum
    cdef char *chcond = _chars(cond)
    c_tqsetc(chcond, n1, n2,  tp, &cnum, <void **> &ceq)
    return cnum

def tqce(target, int n1, int n2, double value):
    cdef char *chtarget = _chars(target)
    c_tqce(chtarget, n1, n2, &value, <void **> &ceq)
    return value

def tqgetv(statvar, int n1, int n2, int n3, arr[double] npf):
    cdef char *chstate = _chars(statvar)
    c_tqgetv(chstate, n1, n2, &n3, &npf[0], <void **>&ceq)
    return n3

def ctuple():
    return c_ntup

def cname(int ph):
    cdef bytes phase = c_cnam[ph]
    return phase

def cnel():
    return c_nel;
    




