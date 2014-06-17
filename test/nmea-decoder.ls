server = require "../main.js"
moment = require \moment
should = require \chai .should!


server.set-decoder "nmea"

describe 'the nmea.receive', (_) ->
  it 'should return the message when the chunk is the message', (done) ->
    server.decoder.flush!
    expected = ["$HEHDT,289.97,T*12"]
    given = "#expected\r"
    result = server.decoder.receive given
    result.should.eql expected
    done!

  it 'should return the message when the chunk contains the message', (done) ->
    server.decoder.flush!
    expected = ["$HEHDT,289.97,T*12"]
    given = ",T*12\r#expected\r$HEHDT,2"
    result = server.decoder.receive given
    result.should.eql expected
    done!

  it 'should return the message from multiple chunks', (done) ->
    server.decoder.flush!
    expected = ["$HEHDT,289.97,T*12"];
    msg1 = ",T*12\r";
    msg2 = "$HEHDT,289";
    msg3 = ".97,T*12";
    msg4 = "\r$HEHDT,2";
    result = server.decoder.receive msg1
    result = server.decoder.receive msg2
    result = server.decoder.receive msg3
    result = server.decoder.receive msg4
    result.should.eql expected
    done!

  it 'should return messages when multiple messages in a chunk', (done) ->
    server.decoder.flush!
    expected = ["$HEHDT,289.97,T*12", "$HEHDT,289.97,T*12"]
    given = "$HEHDT,289.97,T*12\r$HEHDT,289.97,T*12\r"
    result = server.decoder.receive given
    result.should.eql expected
    done!

  it 'should flush the buffer if it reaches 16k', (done) ->
    server.decoder.flush!
    for _ from 0 to 16000
      m = server.decoder.receive \0
    result = server.decoder.buffer-size!
    result.should.equal 0
    done!

  it 'should handle a null character in chunk', (done) ->
    # outside message
    server.decoder.flush!
    expected = ["$HEHDT,289.97,T*12"]
    result = server.decoder.receive "#expected\rA\0Z"
    result.should.eql expected
    # inside message
    server.decoder.flush();
    expected_ = ["$HEHDT,289.97,\0T*12"]
    result_ = server.decoder.receive "#expected_\r"
    result_.should.eql expected_
    done!

  it 'should handle a null chunk', (done) ->
    server.decoder.flush!
    expected = null
    result = server.decoder.receive expected
    (result == expected).should.equal.true
    done!

describe 'the nmea.decode', (_) ->
  it 'should return the decoded HDT', (done) ->
    given = "$HEHDT,289.97,T*12"
    expected = {
      talker       : "HE"
      sentence     : "HDT"
      heading      : 289.97
      heading-type : "T"
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return the decoded HDM', (done) ->
    given = "$HCHDM,302.80,M*10"
    expected = {
      talker       : "HC"
      sentence     : "HDM"
      heading      : 302.80
      heading-type : "M"
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return the decoded VTG', (done) ->
    given = "$GPVTG,113.95,T,113.95,M,00.01,N,00.01,K,D*26"
    expected = {
      talker   : "GP"
      sentence : "VTG"
      cog:
        true: 113.95
        magnetic: 113.95
      sog:
        knots: 0.01
        kph: 0.01
      mode:
        code: "D"
        desc: "Differential"
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return the decoded GGA', (done) ->
    given = "$GPGGA,175621.13,3254.12,S,11530.00,E,2,10,0.9,31.30,M,-33.13,M,020,1000*56"
    expected = {
      talker      : "GP"
      sentence    : "GGA"
      time        : moment.utc "175621.13", "HHmmss.SS"
      wgs84       : lat: -32.902, lon: 115.5, elh: 31.30+(-33.13)
      quality     : {code: 2, desc: "Differential"}
      satellites  : 10
      hdop        : 0.9
      correction-age    : 20
      reference-station : 1000
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!


  it 'should return the decoded GST', (done) ->
    given = "$GPGST,060619.00,0.07,0.04,0.03,020.43,0.03,0.04,0.05*68"
    expected = {
      talker             : "GP"
      sentence           : "GST"
      time               : moment.utc "060619.00", "HHmmss.SS"
      rms                : 0.07
      standard-deviation :
        semi-major : 0.04
        semi-minor : 0.03
        lat        : 0.03
        lon        : 0.04
        elh        : 0.05
      orientation         : 20.43
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return the decoded ZDA', (done) ->
    given = "$GPZDA,060619.00,17,06,2014,00,00*69"
    timedate = "2014-06-17 060619.00"
    expected = {
      talker      : "GP"
      sentence    : "ZDA"
      time: moment.utc timedate, "yyyy-MM-DD HHmmss.SS"
      timezone:
        hours: 0
        minutes: 0
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return the decoded GSV', (done) ->
    given = "$GLGSV,2,1,08,65,28,268,49,71,22,138,44,72,53,198,51,73,14,114,41*6D"
    expected = {
      talker     : "GL"
      sentence   : "GSV"
      totalParts : 2
      partId     : 1
      totalSats  : 8
      sats:
        65:
          elevation : 28
          azimuth   : 268
          snr       : 49
        71:
          elevation : 22
          azimuth   : 138
          snr       : 44
        72:
          elevation : 53
          azimuth   : 198
          snr       : 51
        73:
          elevation : 14
          azimuth   : 114
          snr       : 41
    }
    result = server.decoder.decode given
    result.should.eql expected
    done!

  it 'should return null if checksum is invalid', (done) ->
    given = "$HEHDT,289.97,T*13"
    expected = null
    result = server.decoder.decode given
    (result == null).should.be.true
    done!