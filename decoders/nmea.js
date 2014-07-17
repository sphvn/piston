// Generated by LiveScript 1.2.0
(function(){
  var ref$, dropWhile, takeWhile, drop, floor, splitAt, length, exspan, toArray, unpack, moment, unpackNmea, buffer, decoders, multiSplit, gnssMode, gsaMode, gsaCalc, vtgMode, xdrType, xdrUnit, parseDdmm, invalid, checksum, slice$ = [].slice;
  ref$ = require('prelude-ls').Str, dropWhile = ref$.dropWhile, takeWhile = ref$.takeWhile;
  ref$ = require('prelude-ls'), drop = ref$.drop, floor = ref$.floor, splitAt = ref$.splitAt;
  ref$ = require('../prelude-ext.js'), length = ref$.length, exspan = ref$.exspan, toArray = ref$.toArray;
  unpack = require('../unpacker.js').unpack;
  moment = require('moment');
  unpackNmea = function(b, c){
    return unpack.apply(this, toArray(arguments).concat(['$', '\r']));
  };
  buffer = "";
  this.bufferSize = function(){
    return length(buffer);
  };
  this.flush = function(){
    return buffer = "";
  };
  this.receive = function(chunk){
    var msgs, ref$, buf, msg;
    if (this.bufferSize() >= 16000) {
      this.flush();
    }
    msgs = [];
    for (;;) {
      ref$ = unpackNmea(buffer, chunk), buf = ref$[0], msg = ref$[1];
      buffer = buf;
      if (msg == null) {
        return msgs;
      }
      msgs.push(msg);
      chunk = "";
    }
  };
  this.decode = function(msg){
    var _msg, ref$, checksum, prefix, talker, sentence, parts, decode;
    _msg = drop(1, msg);
    ref$ = exspan('*', _msg), _msg = ref$[0], checksum = ref$[1];
    if (invalid(checksum, _msg)) {
      return null;
    }
    ref$ = exspan(',', _msg), prefix = ref$[0], _msg = ref$[1];
    talker = prefix.substr(0, 2);
    sentence = prefix.substr(2);
    parts = _msg.split(',');
    decode = decoders[sentence.toUpperCase()];
    return import$({
      talker: talker,
      sentence: sentence
    }, decode != null ? decode.apply(this, parts) : void 8);
  };
  decoders = {
    APB: function(status1, status2, xte, xteDir, xteUnit, arriveCirc, arrivePerp, originBrg, originBrgH, wptId, presentBrg, presentBrgH, steerHeading, steerHeadingH, mode){
      return {
        status: status1,
        xte: {
          magnitude: parseFloat(xte),
          dirToSteer: xteDir,
          units: xteUnit
        },
        arrivalCircleEntered: arriveCirc,
        perpPassedWpt: arrivePerp,
        bearing: {
          originToDestination: parseFloat(originBrg),
          presentToDestination: parseFloat(presentBrg)
        },
        destWptId: wptId,
        headingToSteer: parseFloat(headingToSteer),
        mode: mode
      };
    },
    DBS: function(depthFeet, fe, depthMetres, m, depthFathoms, fa){
      return {
        depth: {
          feet: parseFloat(depthFeet),
          metres: parseFloat(depthMetres),
          fathoms: parseFloat(depthFathoms)
        }
      };
    },
    DBT: function(depthFeet, fe, depthMetres, m, depthFathoms, fa){
      return {
        depth: {
          feet: parseFloat(depthFeet),
          metres: parseFloat(depthMetres),
          fathoms: parseFloat(depthFathoms)
        }
      };
    },
    DPT: function(relDepth, offset, rangeScale){
      return {
        relDepth: parseFloat(relDepth),
        offset: parseFloat(offset)
      };
    },
    GGA: function(time, lat, lath, lon, lonh, quality, sats, hdop, alt, altU, gsep, gsepU, age, refid){
      var q;
      q = parseInt(quality);
      return {
        time: moment.utc(time, "HHmmss.SS"),
        wgs84: {
          lat: parseDdmm(lat, lath),
          lon: parseDdmm(lon, lonh),
          elh: parseFloat(alt) + parseFloat(gsep)
        },
        quality: {
          code: q,
          desc: gnssMode(q)
        },
        satellites: parseInt(sats),
        hdop: parseFloat(hdop),
        correctionAge: parseInt(age),
        referenceStation: parseInt(refid)
      };
    },
    GSA: function(m1, m2){
      var sats, i;
      sats = slice$.call(arguments, 2);
      return {
        mode: gsaMode(m1),
        calc: parseInt(m2),
        calcDesc: gsaCalc(parseInt(m2)),
        pdop: parseFloat(sats[12]),
        hdop: parseFloat(sats[13]),
        vdop: parseFloat(sats[14]),
        sats: (function(){
          var i$, to$, results$ = [];
          for (i$ = 0, to$ = sats.length - 4; i$ <= to$; ++i$) {
            i = i$;
            if (sats[i] !== '') {
              results$.push(sats[i]);
            }
          }
          return results$;
        }())
      };
    },
    GST: function(time, rms, smajSd, sminSd, ori, latSd, lonSd, elhSd){
      return {
        time: moment.utc(time, "HHmmss.SS"),
        rms: parseFloat(rms),
        standardDeviation: {
          semiMajor: parseFloat(smajSd),
          semiMinor: parseFloat(sminSd),
          lat: parseFloat(latSd),
          lon: parseFloat(lonSd),
          elh: parseFloat(elhSd)
        },
        orientation: parseFloat(ori)
      };
    },
    GSV: function(n, i, t){
      var sats, ss, s;
      sats = slice$.call(arguments, 3);
      ss = multiSplit(4, sats);
      return {
        totalParts: parseInt(n),
        partId: parseInt(i),
        totalSats: parseInt(t),
        sats: (function(){
          var i$, ref$, len$, results$ = {};
          for (i$ = 0, len$ = (ref$ = ss).length; i$ < len$; ++i$) {
            s = ref$[i$];
            results$[parseInt(s[0])] = {
              elevation: parseInt(s[1]),
              azimuth: parseInt(s[2]),
              snr: parseInt(s[3])
            };
          }
          return results$;
        }())
      };
    },
    HDG: function(heading, deviation, devHem, variation, varHem){
      var _dev, _var;
      _dev = parseFloat(deviation);
      _dev(/^[w]$/i.test(devHem) ? -dev : dev);
      _var = parseFloat(variation);
      _var(/^[w]$/i.test(varHem) ? -_var : _var);
      return {
        heading: parseFloat(heading),
        magneticDev: _dev,
        magneticVar: _var
      };
    },
    HDM: function(heading, type){
      return {
        heading: parseFloat(heading),
        headingType: type
      };
    },
    HDT: function(heading, type){
      return {
        heading: parseFloat(heading),
        headingType: type
      };
    },
    MTW: function(temperature, unit){
      return {
        temperature: parseFloat(temperature),
        unit: unit
      };
    },
    VTG: function(cogT, t, cogM, m, sogKn, n, sogKph, k, mode){
      return {
        cog: {
          'true': parseFloat(cogT),
          magnetic: parseFloat(cogM)
        },
        sog: {
          knots: parseFloat(sogKn),
          kph: parseFloat(sogKph)
        },
        mode: {
          code: mode,
          desc: vtgMode(mode)
        }
      };
    },
    XDR: function(){
      var data, ss, s;
      data = slice$.call(arguments);
      ss = multiSplit(4, data);
      return {
        data: (function(){
          var i$, ref$, len$, results$ = {};
          for (i$ = 0, len$ = (ref$ = ss).length; i$ < len$; ++i$) {
            s = ref$[i$];
            results$[s[3]] = {
              type: xdrType(s[0]),
              value: parseFloat(s[1]) || 0.0,
              unit: xdrUnit(s[0], s[2])
            };
          }
          return results$;
        }())
      };
    },
    ZDA: function(time, day, month, year, tzH, tzM){
      var timedate;
      timedate = year + "-" + month + "-" + day + " " + time;
      return {
        time: moment.utc(timedate, "yyyy-MM-DD HHmmss.SS"),
        timezone: {
          hours: parseInt(tzH),
          minutes: parseInt(tzM)
        }
      };
    }
  };
  multiSplit = function(n, xs){
    var go;
    go = function(acc, xs){
      var ref$, ys, zs;
      switch (false) {
      case xs.length !== 0:
        return acc;
      default:
        ref$ = splitAt(n, xs), ys = ref$[0], zs = ref$[1];
        return go(acc.concat([ys]), zs);
      }
    };
    return go([], xs);
  };
  gnssMode = function(m){
    switch (m) {
    case 0:
      return "Not Valid";
    case 1:
      return "Standalone";
    case 2:
      return "Differential";
    case 3:
      return "Precise";
    case 4:
      return "Kinematic Fixed";
    case 5:
      return "Kinematic Float";
    case 6:
      return "Dead Reckoning";
    case 7:
      return "Manual Input";
    case 8:
      return "Simulator";
    case 9:
      return "Kinematic Float GPS/Glonass";
    default:
      return "Unknown";
    }
  };
  gsaMode = function(m){
    switch (m) {
    case 'A':
      return "Automatic";
    case 'M':
      return "Manual";
    default:
      return "Unknown";
    }
  };
  gsaCalc = function(m){
    switch (m) {
    case 1:
      return "Fix not available";
    case 2:
      return "2D";
    case 3:
      return "3D";
    default:
      return "Unknown";
    }
  };
  vtgMode = function(m){
    switch (m) {
    case 'A':
      return "Autonomous";
    case 'D':
      return "Differential";
    case 'E':
      return "Dead Reckoning";
    case 'M':
      return "Manual Input";
    case 'S':
      return "Simulator";
    case 'N':
      return "Not Valid";
    default:
      return "Unknown";
    }
  };
  xdrType = function(t){
    switch (t) {
    case 'C':
      return "Temperature";
    case 'A':
      return "Angular Displacement";
    case 'D':
      return "Linear Displacement";
    case 'F':
      return "Frequency";
    case 'N':
      return "Force";
    case 'P':
      return "Pressure";
    case 'R':
      return "Flow Rate";
    case 'T':
      return "Tachometer";
    case 'H':
      return "Humidity";
    case 'V':
      return "Volume";
    case 'G':
      return "Generic";
    case 'I':
      return "Current";
    case 'U':
      return "Voltage";
    case 'S':
      return "Switch or Valve";
    case 'L':
      return "Salinity";
    default:
      return "Unknown";
    }
  };
  xdrUnit = function(t, u){
    switch (u) {
    case 'C':
      return "Degrees Celsius";
    case 'D':
      return "Degrees";
    case 'M':
      switch (t) {
      case 'D':
        return "Metres";
      }
      break;
    case 'H':
      return "Hertz";
    case 'N':
      return "Newton";
    case 'B':
      return "Bars";
    case 'P':
      switch (t) {
      case 'P':
        return "Pascal";
      }
      break;
    case 'L':
      return "Litres/second";
    case 'R':
      return "RPM";
    case " ":
      return "None";
    case 'A':
      return "Amperes";
    case 'V':
      return "Volts";
    case 'S':
      return "PPT";
    default:
      return "Unknown";
    }
  };
  parseDdmm = function(str, hem){
    var num, intDegs, decMins, decDegs;
    num = parseFloat(str);
    intDegs = floor(num / 100.0);
    decMins = num - intDegs * 100;
    decDegs = intDegs + decMins / 60.0;
    return /^[ws]$/i.test(hem) ? -decDegs : decDegs;
  };
  invalid = function(cs, msg){
    var chk;
    chk = checksum(msg).toLowerCase();
    return chk !== cs.toLowerCase();
  };
  checksum = function(xs){
    var x, i$, to$, i, hex;
    x = 0;
    for (i$ = 0, to$ = xs.length - 1; i$ <= to$; ++i$) {
      i = i$;
      x = x ^ xs.charCodeAt(i);
    }
    hex = Number(x).toString(16).toUpperCase();
    if (hex.length < 2) {
      return ('00' + hex).slice(-2);
    } else {
      return hex;
    }
  };
  function import$(obj, src){
    var own = {}.hasOwnProperty;
    for (var key in src) if (own.call(src, key)) obj[key] = src[key];
    return obj;
  }
}).call(this);
