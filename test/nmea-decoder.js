// Generated by LiveScript 1.3.1
(function(){
  var nmea, moment, should;
  nmea = require("../decoders/nmea.js");
  moment = require('moment');
  should = require('chai').should();
  describe('the nmea.receive', function(_){
    it('should return the message when the chunk is the message', function(done){
      var expected, given, result;
      nmea.flush();
      expected = ["$HEHDT,289.97,T*12"];
      given = expected + "\r";
      result = nmea.receive(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the message when the chunk contains the message', function(done){
      var expected, given, result;
      nmea.flush();
      expected = ["$HEHDT,289.97,T*12"];
      given = ",T*12\r" + expected + "\r$HEHDT,2";
      result = nmea.receive(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the message from multiple chunks', function(done){
      var expected, msg1, msg2, msg3, msg4, result;
      nmea.flush();
      expected = ["$HEHDT,289.97,T*12"];
      msg1 = ",T*12\r";
      msg2 = "$HEHDT,289";
      msg3 = ".97,T*12";
      msg4 = "\r$HEHDT,2";
      result = nmea.receive(msg1);
      result = nmea.receive(msg2);
      result = nmea.receive(msg3);
      result = nmea.receive(msg4);
      result.should.eql(expected);
      return done();
    });
    it('should return messages when multiple messages in a chunk', function(done){
      var expected, given, result;
      nmea.flush();
      expected = ["$HEHDT,289.97,T*12", "$HEHDT,289.97,T*12"];
      given = "$HEHDT,289.97,T*12\r$HEHDT,289.97,T*12\r";
      result = nmea.receive(given);
      result.should.eql(expected);
      return done();
    });
    it('should flush the buffer if it reaches 16k', function(done){
      var i$, _, m, result;
      nmea.flush();
      for (i$ = 0; i$ <= 1600; ++i$) {
        _ = i$;
        m = nmea.receive('0000000000');
      }
      result = nmea.bufferSize();
      result.should.equal(0);
      return done();
    });
    it('should handle a null character in chunk', function(done){
      var expected, result, expected_, result_;
      nmea.flush();
      expected = ["$HEHDT,289.97,T*12"];
      result = nmea.receive(expected + "\rA\0Z");
      result.should.eql(expected);
      nmea.flush();
      expected_ = ["$HEHDT,289.97,\0T*12"];
      result_ = nmea.receive(expected_ + "\r");
      result_.should.eql(expected_);
      return done();
    });
    return it('should handle a null chunk', function(done){
      var expected, result;
      nmea.flush();
      expected = null;
      result = nmea.receive(expected);
      (result === expected).should.equal['true'];
      return done();
    });
  });
  describe('the nmea.decode', function(_){
    it('should return the decoded APB', function(done){
      var given, expected, result;
      given = "$GPAPB,A,A,0.10,R,N,V,V,011,M,DEST,011,M,011,M,A*51";
      expected = {
        talker: "GP",
        sentence: "APB",
        status: "A",
        xte: {
          dirToSteer: "R",
          magnitude: 0.1,
          units: "N"
        },
        arrivalCircleEntered: "V",
        perpPassedWpt: "V",
        bearing: {
          originToDestination: 11,
          presentToDestination: 11
        },
        destWptId: "DEST",
        headingToSteer: 11,
        mode: "A"
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded DBS', function(done){
      var given, expected, result;
      given = "$SDDBS,2.82,f,0.86,M,0.47,F*34";
      expected = {
        talker: "SD",
        sentence: "DBS",
        depth: {
          feet: 2.82,
          metres: 0.86,
          fathoms: 0.47
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded DBT', function(done){
      var given, expected, result;
      given = "$SDDBT,1330.5,f,0405.5,M,0221.6,F*31";
      expected = {
        talker: "SD",
        sentence: "DBT",
        depth: {
          feet: 1330.5,
          metres: 405.5,
          fathoms: 221.6
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded DPT', function(done){
      var given, expected, result;
      given = "$SDDPT,2.82,5.00*5A";
      expected = {
        talker: "SD",
        sentence: "DPT",
        relDepth: 2.82,
        offset: 5.00
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded GGA', function(done){
      var given, expected, result;
      given = "$GPGGA,175621.13,3254.12,S,11530.00,E,2,10,0.9,31.30,M,-33.13,M,020,1000*56";
      expected = {
        talker: "GP",
        sentence: "GGA",
        time: moment.utc("175621.13", "HHmmss.SS"),
        wgs84: {
          lat: -32.902,
          lon: 115.5,
          elh: 31.30 + (-33.13)
        },
        quality: {
          code: 2,
          desc: "Differential"
        },
        satellites: 10,
        hdop: 0.9,
        correctionAge: 20,
        referenceStation: 1000
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded GSA', function(done){
      var given, expected, result;
      given = "$GPGSA,M,3,04,07,30,10,08,,,,,,,,7.2,5.6,4.4*31";
      expected = {
        talker: "GP",
        sentence: "GSA",
        mode: "Manual",
        calc: 3,
        calcDesc: "3D",
        sats: ["04", "07", "30", "10", "08"],
        pdop: 7.2,
        hdop: 5.6,
        vdop: 4.4
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded GST', function(done){
      var given, expected, result;
      given = "$GPGST,060619.00,0.07,0.04,0.03,020.43,0.03,0.04,0.05*68";
      expected = {
        talker: "GP",
        sentence: "GST",
        time: moment.utc("060619.00", "HHmmss.SS"),
        rms: 0.07,
        standardDeviation: {
          semiMajor: 0.04,
          semiMinor: 0.03,
          lat: 0.03,
          lon: 0.04,
          elh: 0.05
        },
        orientation: 20.43
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded GSV', function(done){
      var given, expected, result;
      given = "$GLGSV,2,1,08,65,28,268,49,71,22,138,44,72,53,198,51,73,14,114,41*6D";
      expected = {
        talker: "GL",
        sentence: "GSV",
        totalParts: 2,
        partId: 1,
        totalSats: 8,
        sats: {
          65: {
            elevation: 28,
            azimuth: 268,
            snr: 49
          },
          71: {
            elevation: 22,
            azimuth: 138,
            snr: 44
          },
          72: {
            elevation: 53,
            azimuth: 198,
            snr: 51
          },
          73: {
            elevation: 14,
            azimuth: 114,
            snr: 41
          }
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded HDM', function(done){
      var given, expected, result;
      given = "$HCHDM,302.80,M*10";
      expected = {
        talker: "HC",
        sentence: "HDM",
        heading: 302.80,
        headingType: "M"
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded HDT', function(done){
      var given, expected, result;
      given = "$HEHDT,289.97,T*12";
      expected = {
        talker: "HE",
        sentence: "HDT",
        heading: 289.97,
        headingType: "T"
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded MTW', function(done){
      var given, expected, result;
      given = "$SDMTW,26.8,C*08";
      expected = {
        talker: "SD",
        sentence: "MTW",
        temperature: 26.8,
        unit: "C"
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded VTG', function(done){
      var given, expected, result;
      given = "$GPVTG,113.95,T,113.95,M,00.01,N,00.01,K,D*26";
      expected = {
        talker: "GP",
        sentence: "VTG",
        cog: {
          'true': 113.95,
          magnetic: 113.95
        },
        sog: {
          knots: 0.01,
          kph: 0.01
        },
        mode: {
          code: "D",
          desc: "Differential"
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded XDR', function(done){
      var given, expected, result;
      given = "$YXXDR,C,,C,WCHR,C,,C,WCHT,C,,C,HINX,P,1.0187,B,STNP*44";
      expected = {
        talker: "YX",
        sentence: "XDR",
        data: {
          "WCHR": {
            type: "Temperature",
            value: 0.0,
            unit: "Degrees Celsius"
          },
          "WCHT": {
            type: "Temperature",
            value: 0.0,
            unit: "Degrees Celsius"
          },
          "HINX": {
            type: "Temperature",
            value: 0.0,
            unit: "Degrees Celsius"
          },
          "STNP": {
            type: "Pressure",
            value: 1.0187,
            unit: "Bars"
          }
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    it('should return the decoded ZDA', function(done){
      var given, timedate, expected, result;
      given = "$GPZDA,060619.00,17,06,2014,00,00*69";
      timedate = "2014-06-17 060619.00";
      expected = {
        talker: "GP",
        sentence: "ZDA",
        time: moment.utc(timedate, "yyyy-MM-DD HHmmss.SS"),
        timezone: {
          hours: 0,
          minutes: 0
        }
      };
      result = nmea.decode(given);
      result.should.eql(expected);
      return done();
    });
    return it('should return null if checksum is invalid', function(done){
      var given, expected, result;
      given = "$HEHDT,289.97,T*13";
      expected = null;
      result = nmea.decode(given);
      (result === null).should.be['true'];
      return done();
    });
  });
}).call(this);
