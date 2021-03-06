nmea   = require "../decoders/nmea.js"
moment = require \moment
should = require \chai .should!

describe 'the nmea.receive', (_) ->
  it 'should return the message when the chunk is the message', (done) ->
    nmea.flush!
    expected = ["$HEHDT,289.97,T*12"]
    given = "#expected\r"
    result = nmea.receive given
    result.should.eql expected
    done!

  it 'should return the message when the chunk contains the message', (done) ->
    nmea.flush!
    expected = ["$HEHDT,289.97,T*12"]
    given = ",T*12\r#expected\r$HEHDT,2"
    result = nmea.receive given
    result.should.eql expected
    done!

  it 'should return the message from multiple chunks', (done) ->
    nmea.flush!
    expected = ["$HEHDT,289.97,T*12"];
    msg1 = ",T*12\r";
    msg2 = "$HEHDT,289";
    msg3 = ".97,T*12";
    msg4 = "\r$HEHDT,2";
    result = nmea.receive msg1
    result = nmea.receive msg2
    result = nmea.receive msg3
    result = nmea.receive msg4
    result.should.eql expected
    done!

  it 'should return messages when multiple messages in a chunk', (done) ->
    nmea.flush!
    expected = ["$HEHDT,289.97,T*12", "$HEHDT,289.97,T*12"]
    given = "$HEHDT,289.97,T*12\r$HEHDT,289.97,T*12\r"
    result = nmea.receive given
    result.should.eql expected
    done!

  it 'should flush the buffer if it reaches 16k', (done) ->
    nmea.flush!
    for _ from 0 to 1600
      m = nmea.receive \0000000000
    result = nmea.buffer-size!
    result.should.equal 0
    done!

  it 'should handle a null character in chunk', (done) ->
    # outside message
    nmea.flush!
    expected = ["$HEHDT,289.97,T*12"]
    result = nmea.receive "#expected\rA\0Z"
    result.should.eql expected
    # inside message
    nmea.flush!
    expected_ = ["$HEHDT,289.97,\0T*12"]
    result_ = nmea.receive "#expected_\r"
    result_.should.eql expected_
    done!

  it 'should handle a null chunk', (done) ->
    nmea.flush!
    expected = null
    result = nmea.receive expected
    (result == expected).should.equal.true
    done!

describe 'the nmea.decode', (_) ->
  it 'should return the decoded APB', (done) ->
    given = "$GPAPB,A,A,0.10,R,N,V,V,011,M,DEST,011,M,011,M,A*51"
    expected = {
      talker      : "GP"
      sentence    : "APB"
      status: "A"
      xte:
        dir-to-steer: "R"
        magnitude: 0.1
        units: "N"
      arrival-circle-entered: "V"
      perp-passed-wpt: "V"
      bearing:
        origin-to-destination: 11
        present-to-destination: 11
      dest-wpt-id: "DEST"
      heading-to-steer: 11
      mode: "A"
    }
    result = nmea.decode given
    result.should.eql expected
    done!


  it 'should return the decoded DBS', (done) ->
    given = "$SDDBS,2.82,f,0.86,M,0.47,F*34"
    expected = {
      talker      : "SD"
      sentence    : "DBS"
      depth:
        feet    : 2.82
        metres  : 0.86
        fathoms : 0.47
    }
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded DBT', (done) ->
    given = "$SDDBT,1330.5,f,0405.5,M,0221.6,F*31"
    expected = {
      talker      : "SD"
      sentence    : "DBT"
      depth:
        feet    : 1330.5
        metres  : 405.5
        fathoms : 221.6
    }
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded DPT', (done) ->
    given = "$SDDPT,2.82,5.00*5A" # NMEA spec says it has a further field being the "Maximum range scale in use"
    expected = {
      talker      : "SD"
      sentence    : "DPT"
      rel-depth   : 2.82
      offset      : 5.00
      #range-scale : null
    }
    result = nmea.decode given
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
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded GSA', (done) ->
    given = "$GPGSA,M,3,04,07,30,10,08,,,,,,,,7.2,5.6,4.4*31"
    expected = {
      talker    : "GP"
      sentence  : "GSA"
      mode      : "Manual"
      calc      : 3
      calc-desc : "3D"
      sats:
        "04"
        "07"
        "30"
        "10"
        "08"
      pdop      : 7.2
      hdop      : 5.6
      vdop      : 4.4
    }
    result = nmea.decode given
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
    result = nmea.decode given
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
    result = nmea.decode given
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
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded HDT', (done) ->
    given = "$HEHDT,289.97,T*12"
    expected = {
      talker       : "HE"
      sentence     : "HDT"
      heading      : 289.97
      heading-type : "T"
    }
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded MTW', (done) ->
    given = "$SDMTW,26.8,C*08"
    expected = {
      talker       : "SD"
      sentence     : "MTW"
      temperature  : 26.8
      unit         : "C"
    }
    result = nmea.decode given
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
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return the decoded XDR', (done) ->
    given = "$YXXDR,C,,C,WCHR,C,,C,WCHT,C,,C,HINX,P,1.0187,B,STNP*44"
    expected = {
      talker      : "YX"
      sentence    : "XDR"
      data:
        "WCHR":
          type  : "Temperature"
          value : 0.0
          unit  : "Degrees Celsius"
        "WCHT":
          type  : "Temperature"
          value : 0.0
          unit  : "Degrees Celsius"
        "HINX":
          type  : "Temperature"
          value : 0.0
          unit  : "Degrees Celsius"
        "STNP":
          type  : "Pressure"
          value : 1.0187
          unit  : "Bars"
    }
    result = nmea.decode given
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
    result = nmea.decode given
    result.should.eql expected
    done!

  it 'should return null if checksum is invalid', (done) ->
    given = "$HEHDT,289.97,T*13"
    expected = null
    result = nmea.decode given
    (result == null).should.be.true
    done!