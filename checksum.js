this.get = function (s) {
	var i, _len, chk;
    _len = s.length - 1;
    chk = 0;
    for (i = 0; i <= _len; ++i) {
        chk ^= s.charCodeAt(i);
    }
    console.log(chk);
    return chk;
}
