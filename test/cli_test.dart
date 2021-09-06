import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:test/test.dart';
import 'package:uprt/lib.dart';

void main() {
  testRun = true;
  //Update version info
  MetaUpdate("pubspec.yaml").writeMetaDartFile("lib/src/meta.dart");
  //run all test
  testUpRooted();
}

/// ******* DEFINE SOME TEST VALUES****************************
///
void testUpRooted() {
//Test whether have same number of lease components
//in final file and have expected length
  List<String> args = <String>[
    "-i",
    "test/test-data/lease-list-infile.csv",
    "-L",
    "192.168.0.1",
    "-H",
    "192.168.0.254",
    "-b",
    "test-output-file"
  ];

  List<String> argsTestBase = <String>[
    "-i",
    "test/test-data/lease-list-infile.csv",
    "-L",
    "192.168.0.1",
    "-H",
    "192.168.0.254",
    "-b",
    "test-output-file",
    "-d",
    "test/test-output",
    "-w"
  ];

  argResults = cliArgs.getArgs(args);

  ///*********** TEST METHODS */

  bool isCorrectLeaseMapLength(
      Map<String, List<String>> leaseMap, int listLength) {
    print(
        """
List Map length of host is ${leaseMap[lbHost]!.length}, expected is $listLength""");
    return ((leaseMap[lbHost]?.length == leaseMap[lbIp]?.length) &&
        (leaseMap[lbIp]?.length == leaseMap[lbMac]?.length) &&
        (leaseMap[lbHost]?.length == listLength));
  }

  Ip ip = Ip();
/**************** TESTS: *******************/
  test('metaCheck', () {
    Directory pubSpecTestDir = Directory.systemTemp.createTempSync("uprt-test");
    File pubSpecTestFile =
        File(p.join(pubSpecTestDir.absolute.path, "pubspec-test.yaml"));

    pubSpecTestFile.writeAsStringSync(
        """
    name: uprt
    description: A tool to migrate static leases between DD-WRT, OpenWrt, OPNsense, Mikrotik, and pfSense routers. Also supports cvs and json.
    version: 2019.09.001

    """);

    MetaUpdate mu = MetaUpdate(pubSpecTestFile.absolute.path);

    expect(mu.verifyLatestVersionFromPubSpec(), MetaCheck.mismatch);

    pubSpecTestFile.writeAsStringSync(
        """
    name: ${meta['name']}
    description: ${meta['description']}
    version: ${meta['version']}

    """);
    expect(mu.verifyLatestVersionFromPubSpec(), MetaCheck.match);

    mu = MetaUpdate("file-does-not-exist.yaml");
    expect(mu.verifyLatestVersionFromPubSpec(), MetaCheck.runningAsBinary);

    pubSpecTestDir.delete();
  });
  test('isWithinRange', () {
    argResults = cliArgs.getArgs(args);
    expect(
        ip.isWithinRange("192.168.0.23", "192.168.0.1", "192.168.0.254"), true);
    expect(
        ip.isWithinRange("192.168.0.2", "192.168.0.1", "192.168.0.254"), true);
    expect(
        ip.isWithinRange("192.168.0.1", "192.168.0.1", "192.168.0.254"), true);
    expect(
        ip.isWithinRange("192.168.0.25", "192.168.0.1", "192.168.0.254"), true);
    expect(
        ip.isWithinRange("192.168.0.0", "192.168.0.1", "192.168.0.254"), false);
    expect(ip.isWithinRange("192.168.0.254", "192.168.0.1", "192.168.0.254"),
        true);
    expect(ip.isWithinRange("192.168.0.255", "192.168.0.1", "192.168.0.254"),
        false);
    expect(
        ip.isWithinRange("9990.0.255", "192.168.0.1", "192.168.0.254"), false);
  });
  test('isIp4', () {
    expect(ip.isIp4("192.168..."), false);
    expect(ip.isIp4("112.255.242.1"), true);
    expect(ip.isIp4("not-an-ip"), false);
    expect(ip.isIp4("0.0.0.0"), true);
    expect(ip.isIp4("11111"), false);
    expect(ip.isIp4("255.255.255.255"), true);
    expect(ip.isIp4("192.168004"), false);
    expect(ip.isIp4("notanip"), false);
  });

  test('ipStrToNum', () {
    expect(ip.ipStrToNum("192.158.0.1"), 192158000001);
    expect(ip.ipStrToNum("192.158.244.244"), 192158244244);
    expect(() => ip.ipStrToNum("192158.244.244"),
        checkErrorMessage("Not an ip4 Address"));
    expect(() => ip.ipStrToNum("192158.244.dd"),
        checkErrorMessage("Not an ip4 Address"));
    expect(() => ip.ipStrToNum(""), checkErrorMessage("Not an ip4 Address"));
    expect(() => ip.ipStrToNum('\$\%#@192.168'),
        checkErrorMessage("Not an ip4 Address"));
  });

  test("Args", () {
    /* test if multiple options work */

    args = <String>[...argsTestBase];
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "c");

    args[1] = "test/test-data/lease-list-infile.ddwrt";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "d");

    args[1] = "test/test-data/lease-list-infile.json";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "j");

    args[1] = "test/test-data/lease-list-infile.rsc";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "m");

    args[1] = "test/test-data/lease-list-infile.openwrt";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "o");

    args[1] = "test/test-data/lease-list-infile-opn.xml";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "n");

    args[1] = "test/test-data/lease-list-infile-pfs.xml";
    argResults = cliArgs.getArgs(args);
    expect(cliArgs.getInputType(), "p");

    args[1] = "test/test-data/lease-list-infile.dd";
    argResults = cliArgs.getArgs(args);
    expect(
        () => cliArgs.getInputType(),
        checkErrorMessage(
            ("Unable to determine file type, please specify using -t")));

/* Test Mandatory */
    args = <String>[...argsTestBase];
    args.remove("-i");
    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("Missing mandatory option(s): input-file"));

    args = <String>[...argsTestBase];
    args.remove("-H");
    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("Missing mandatory option(s): ip-high-address"));

    args = <String>[...argsTestBase];
    args.remove("-L");
    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("Missing mandatory option(s): ip-low-address"));

    args = <String>[...argsTestBase];
    args.remove("-b");
    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("Missing mandatory option(s): base-name"));

/** Test for Missing Arguments to options*/
    args = <String>[
      "-L",
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-g",
      "cdjmnop",
      // "-L",
      "192.168.0.1",
      //"--ip-high-address",
      "192.168.0.254",
      "-b",
      "test-base-name",
      "-d",
      "test/test-output",
      "-w"
    ];

    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("Missing mandatory option"));
    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("is missing argument and is set to -i"));

    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "-d",
      "test/test-output",
      "-w"
    ];

    argResults = cliArgs.getArgs(args);

    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("is missing argument and is set to -d"));

    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-H",
      "192.168.0.254",
      "-b",
      "base-file",
      "-d",
      "-w",
      "-L"
    ];

    expect(() => cliArgs.getArgs(args),
        checkErrorMessage('Missing argument for "ip-low-address"'));
    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-L",
      "192.168.0.1",
      "--ip-high-address",
      "192.168.0.254",
      "-b",
      "--log-file-path",
      "-d",
      "test/test-output",
      "-w"
    ];

    argResults = cliArgs.getArgs(args);

    expect(() => cliArgs.checkArgs(),
        checkErrorMessage("is missing argument and is set to --log-file-path"));

    /* test if argument is an option without a hyphen it doesnt trigger error, 
    in this example,
    it's -g d where there is a -d option for directory */

    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-g",
      "d",
      "-L",
      "192.168.0.1",
      "--ip-high-address",
      "192.168.0.254",
      "-d",
      "test/test-output",
      "-w",
      "-b",
      "test-file"
    ];

    argResults = cliArgs.getArgs(args);

    expect(() => cliArgs.checkArgs(), returnsNormally);

    /* test if multiple options work */

    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-g",
      "cdjmnop",
      "-L",
      "192.168.0.1",
      "--ip-high-address",
      "192.168.0.254",
      "-b",
      "test-base-name",
      "-d",
      "test/test-output",
      "-w"
    ];

    argResults = cliArgs.getArgs(args);
    expect(() => cliArgs.checkArgs(), returnsNormally);
  });

  test('ipRandomMac', () {
    for (int i = 0; i < 50; i++) {
      expect(ip.isMacAddress(ip.getRandomMacAddress()), true);
    }
    expect(ip.isMacAddress("01:19:29:C6:26:35"), true);
    expect(ip.isMacAddress("77:06:90:8F:F2:AD"), true);
    expect(ip.isMacAddress("2B:0B:A5:7A:BC:13"), true);
    expect(ip.isMacAddress("3A:DE:97:22:68:75"), true);
    expect(ip.isMacAddress("71:65:DA:DB:0E:3C"), true);

    expect(ip.isMacAddress("asdf:03:0323:"), false);
    expect(ip.isMacAddress("23:4f:03:0323"), false);
    expect(ip.isMacAddress("99:33:3b:3a:35:2g"), false);
    expect(ip.isMacAddress("71:65:DA:DB:0E:C"), false);
  });

  test('isJson', () {
    Json json = Json();

//  csv->json
    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-t",
      "c",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);
    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

//ddwrt->json
    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.ddwrt",
      "-t",
      "d",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

    //mikrotik->json
    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.rsc",
      "-t",
      "m",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

    //openwrt->json
    args = <String>[
      "-i",
      "test/test-data/lease-list-infile.openwrt",
      "-t",
      "o",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);
    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

//opnsense->json
    args = <String>[
      "-i",
      'test/test-data/lease-list-infile-opn.xml',
      "-t",
      "n",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

    //pfsense->json
    args = <String>[
      "-i",
      'test/test-data/lease-list-infile-pfs.xml',
      "-t",
      "p",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    expect(
        json.isContentValid(
            fileContents: File("test/test-output/test-output-file.json")
                .readAsStringSync()),
        true);

    String filePath = "test/test-data/lease-list-infile.json";
    String fileContents = File(filePath).readAsStringSync();

    expect(json.isContentValid(fileContents: fileContents), true);
    expect(
        json.isContentValid(fileContents: '{"item1: value", "value"}'), false);

    expect(
        json.isJson('asld;asdf32323 asdfasdf [{23423} {asdf:asdfasdf'), false);
    expect(json.isJson('{"item1: value", "item2: value"}'), false);

    expect(
        json.isJson(
            '{["item1: value", "value"} {"item1: value", item2: "value"}]'),
        false);
    expect(json.isJson('{["item1: value", "value"} , {"item1: value value"}]'),
        false);

    expect(
        json.isJson(
            '''[ { "item1" : 2, "item2" : "value" }, { "item3" : "value", "item4" : "value" } ]'''),
        true);
  });

  test('isMikrotik', () {
    Mikrotik mikrotik = Mikrotik();
    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "m",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    String badMikrotik =
        """
    /ip dhcp-server lease 
    add mac-address= address=192.168.0.2 server=defconf 
    add mac-address=AC:18:26:55:7B:66 address=192.168.0.146 server=defconf
    """;

    String badMikrotik2 =
        """
    /ip dhcp-server lease 
    add mac-address= address=192.168.0.2 server=defconf 
    add mac-address=dasdfe =printer address=192.168.0.146 server=defconf
    """;
    String badMikrotik3 =
        """
    /ip dhcp-server lease 
    add mac-address= address=192.168.0.2 server=defconf 
    add mac-address=AC:18:26:55:7B:66 address=192168.0146 server=defconf
    """;
    expect(mikrotik.isFileValid("test/test-output/test-output-file.rsc"), true);
    expect(mikrotik.isFileValid("test/test-data/lease-list-infile.rsc"), true);
    expect(
        mikrotik.isFileValid("test/test-data/lease-list-infile.json"), false);
    expect(mikrotik.isContentValid(fileContents: badMikrotik), false);
    expect(mikrotik.isContentValid(fileContents: badMikrotik2), false);
    expect(mikrotik.isContentValid(fileContents: badMikrotik3), false);
    expect(mikrotik.isContentValid(fileContents: "hd nothing here"), false);
    expect(mikrotik.isContentValid(fileContents: ""), false);
  });

  test('isOpenWrt', () {
    OpenWrt openwrt = OpenWrt();
    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "o",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    LineSplitter lineSplitter = LineSplitter();

    List<String> goodOpenWrt = lineSplitter.convert(
        """
 config host
             option mac '00:24:1D:D3:A0:C2'
             option name 'SATURN'          
             option ip '192.168.0.2'
 config host
             option mac 'AC:18:26:55:7B:66'
             option name 'printer'          
             option ip '192.168.0.146'
 config host
             option mac '00:08:CA:F5:01:C5'
             option name 'LivingRoomTv'          
             option ip '192.168.0.102'
    """);

    List<String> badOpenWrt = lineSplitter.convert(
        """
 config host
             option mac 'AC:18:26:55:7B:66'
             option name 'printer'          
    """);

    List<String> badOpenWrt2 = lineSplitter.convert(
        """
 config host
             option mac 'AC:18:26:55:7B:66'
             option name 'printer'          
             option ip '192.168.0.146'
 config host
             option mac '08:CA:F5:01:C5'
             option ip '192.168.0.102'
 
    """);

    List<String> badOpenWrt3 = lineSplitter.convert(
        """
 config host
             option mac 'AC:18:26:55:7B:66'
             option name 'printer'          
             option ip '192.168.0.146'
 config host
             option mac '00:08:CA:F5:01:C5'
             option name 'LivingRoomTv-PC'          
             option ip '192.1680.102'
 
    """);

    expect(
        openwrt.isFileValid("test/test-data/lease-list-infile.openwrt"), true);
    expect(openwrt.isFileValid("test/test-data/lease-list-infile.json"), false);
    expect(openwrt.isContentValid(fileLines: goodOpenWrt), true);
    expect(openwrt.isContentValid(fileLines: badOpenWrt2), false);
    expect(openwrt.isContentValid(fileLines: badOpenWrt3), false);
    expect(openwrt.isContentValid(fileLines: badOpenWrt), false);
    // ignore: always_specify_types
    expect(openwrt.isContentValid(fileLines: [""]), false);
  });

  test('isDdWrt', () {
    Ddwrt ddwrt = Ddwrt();
    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "d",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    String goodDdWrt =
        '''
C4:4D:02:A0:E1:96=WHis=192.168.0.3=1440 7F:B7:26:C3:A8:D3=FxwzLDsBK=192.168.0.4=1440 FC:D6:B5:48:65:3D=agXCrZIQT=192.168.0.5=1440 F4:34:E2:3A:F9:30=umTiNUO=192.168.0.6=1440 89:2A:F0:C5:2A:30=KnOtLxjPCm=192.168.0.7=1440 A1:C6:4E:4A:E6:96=EfnktBOZWh=192.168.0.8=1440 D1:F4:18:48:A9:C0=vAYoTegH=192.168.0.9=1440 56:A5:2B:40:39:7F=mgeLTnQV=192.168.0.10=1440 28:5B:98:CD:B5:34=vlrZbMUO=192.168.0.11=1440 61:88:68:5E:86:7A=gfrM=192.168.0.12=1440 90:69:74:25:F0:49=CQvAEsca=192.168.0.13=1440 D6:55:91:F0:F2:89=EBknxyhwO=192.168.0.14=1440 90:83:FA:69:F2:74=GxhW=192.168.0.15=1440 BD:E0:4D:82:D1:8E=bcqGmaMSP=192.168.0.16=1440 9F:53:D9:17:4E:06=lJujxAzHe=192.168.0.17=1440 79:F3:07:D9:69:30=oIcqN=192.168.0.18=1440 49:FB:D4:AA:0A:0B=HFGJPW=192.168.0.19=1440 84:2C:F8:4F:26:E6=QJyNHnM=192.168.0.20=1440 BD:54:4A:F8:6F:21=ZxNeOCmfQ=192.168.0.21=1440 8D:4D:BC:92:C1:BD=OaMYUo=192.168.0.22=1440 B1:3E:2E:D7:55:EC=enpW=192.168.0.23=1440 15:55:AD:83:79:5B=zcnktlj=192.168.0.24=1440 05:47:4B:16:7B:B5=dHMXslJ=192.168.0.25=1440 3C:EB:57:06:8B:C0=ktwBTWFI=192.168.0.26=1440 97:E4:42:BA:27:0F=MgnHF=192.168.0.27=1440 8D:B8:3D:4B:F7:67=VFfXTH=192.168.0.28=1440 49:18:D0:A8:8E:F2=JnCOzm=192.168.0.29=1440 CF:CE:63:CB:4C:06=YAEBJzaPdl=192.168.0.30=1440 43:E1:7E:A9:58:94=gJmHPo=192.168.0.31=1440 CE:CC:9A:68:08:B8=oiFzC=192.168.0.32=1440 ED:AB:20:91:4B:3F=ZAcgWwsY=192.168.0.33=1440 A6:EF:DD:60:9A:40=ansiZ=192.168.0.34=1440 7E:0E:0F:7F:F4:9F=rvJf=192.168.0.35=1440 3A:9D:95:21:BA:43=NjXMRTW=192.168.0.36=1440 B7:B4:7E:1C:04:BE=vMzVq=192.168.0.37=1440 C2:49:BB:82:02:A2=NYptZcWBHo=192.168.0.38=1440 3D:26:5D:42:91:3F=KpWxe=192.168.0.39=1440 81:67:FF:FD:AB:60=SVpRvIl=192.168.0.40=1440 78:CE:DF:86:AE:A9=rVBv=192.168.0.41=1440 03:8E:E4:08:39:0E=YrUbFEk=192.168.0.183=1440 E8:96:FE:08:82:F0=QkChN=192.168.0.103=1440 53:5F:F7:11:38:1E=WwRhy=192.168.0.192=1440 EB:BF:B7:B7:6E:71=vESR=192.168.0.200=1440 E5:3B:F3:1D:32:66=sSwpycbOa=192.168.0.210=1440 7D:A6:13:0F:DF:3D=LAbwKS=192.168.0.225=1440 8E:34:32:C9:E8:5A=SYUNe=192.168.0.243=1440 5B:92:24:9F:01:EB=muYhDI=192.168.0.232=1440''';

    String badDdWrt =
        '''
      C4:4D:02:A0:E1:96=WHis=192.168.0.3=1440 7F:B7:26:C3:A8=FxwzLDsBK=192.168.0.4=1440 FC:D6:B5:48:65:3D=agXCrZIQT=192.168.5=1440 F4:34:E2:3A:F9:30=umTiNUO=192.168.0.6=1440 89:2A:F0:C5:2A:30=KnOtLxjPCm=192.168.0.7=1440 A1:C6:4E:4A:E6:96=EfnktBOZWh=192.168.0.8=1440 D1:F4:18:48:A9:C0=vAYoTegH=192.168.0.9=1440 56:A5:2B:40:39:7F=mgeLTnQV=192.168.0.10=1440 28:5B:98:CD:B5:34=vlrZbMUO=192.168.0.11=1440 61:88:68:5E:86:7A=gfrM=192.168.0.12=1440 90:69:74:25:F0:49=CQvAEsca=192.168.0.13=1440 D6:55:91:F0:F2:89=EBknxyhwO=192.168.0.14=1440 90:83:FA:69:F2:74=GxhW=192.168.0.15=1440 BD:E0:4D:82:D1:8E=bcqGmaMSP=192.168.0.16=1440 9F:53:D9:17:4E:06=lJujxAzHe=192.168.0.17=1440 79:F3:07:D9:69:30=oIcqN=192.168.0.18=1440 49:FB:D4:AA:0A:0B=HFGJPW=192.168.0.19=1440 84:2C:F8:4F:26:E6=QJyNHnM=192.168.0.20=1440 BD:54:4A:F8:6F:21=ZxNeOCmfQ=192.168.0.21=1440 8D:4D:BC:92:C1:BD=OaMYUo=192.168.0.22=1440 B1:3E:2E:D7:55:EC=enpW=192.168.0.23=1440 15:55:AD:83:79:5B=zcnktlj=192.168.0.24=1440 05:47:4B:16:7B:B5=dHMXslJ=192.168.0.25=1440 3C:EB:57:06:8B:C0=ktwBTWFI=192.168.0.26=1440 97:E4:42:BA:27:0F=MgnHF=192.168.0.27=1440 8D:B8:3D:4B:F7:67=VFfXTH=192.168.0.28=1440 49:18:D0:A8:8E:F2=JnCOzm=192.168.0.29=1440 CF:CE:63:CB:4C:06=YAEBJzaPdl=192.168.0.30=1440 43:E1:7E:A9:58:94=gJmHPo=192.168.0.31=1440 CE:CC:9A:68:08:B8=oiFzC=192.168.0.32=1440 ED:AB:20:91:4B:3F=ZAcgWwsY=192.168.0.33=1440 A6:EF:DD:60:9A:40=ansiZ=192.168.0.34=1440 7E:0E:0F:7F:F4:9F=rvJf=192.168.0.35=1440 3A:9D:95:21:BA:43=NjXMRTW=192.168.0.36=1440 B7:B4:7E:1C:04:BE=vMzVq=192.168.0.37=1440 C2:49:BB:82:02:A2=NYptZcWBHo=192.168.0.38=1440 3D:26:5D:42:91:3F=KpWxe=192.168.0.39=1440 81:67:FF:FD:AB:60=SVpRvIl=192.168.0.40=1440 78:CE:DF:86:AE:A9=rVBv=192.168.0.41=1440 03:8E:E4:08:39:0E=YrUbFEk=192.168.0.183=1440 E8:96:FE:08:82:F0=QkChN=192.168.0.103=1440 53:5F:F7:11:38:1E=WwRhy=192.168.0.192=1440 EB:BF:B7:B7:6E:71=vESR=192.168.0.200=1440 E5:3B:F3:1D:32:66=sSwpycbOa=192.168.0.210=1440 7D:A6:13:0F:DF:3D=LAbwKS=192.168.0.225=1440 8E:34:32:C9:E8:5A=SYUNe=192.168.0.243=1440 5B:92:24:9F:01:EB=muYhDI=192.168.0.232=1440''';

    String badDdWrt2 =
        '''
C4:4D:02:A0:E1:96=WHis=192.168.0.3=1440 7F:B7:26:C3:A8:D3=FxwzLDsBK=192.168.0.4=1440 FC:D6:B5:48:65:3D=agXCrZIQT=192168.0.5=1440 F4:34:E2:3A:F9:30=192.168.0.6=1440 89:2A:F0:C5:2A:30=KnOtLxjPCm=192.168.0.7=1440 A1:C6:4E:4A:E6:96=EfnktBOZWh=192.168.0.8=1440 D1:F4:18:48:A9:C0=vAYoTegH=192.168.0.9=1440 56:A5:2B:40:39:7F=mgeLTnQV=192.168.0.10=1440 28:5B:98:CD:B5:34=vlrZbMUO=192.168.0.11=1440 61:88:68:5E:86:7A=gfrM=192.168.0.12=1440 90:69:74:25:F0:49=CQvAEsca=192.168.0.13=1440 D6:55:91:F0:F2:89=EBknxyhwO=192.168.0.14=1440 90:83:FA:69:F2:74=GxhW=192.168.0.15=1440 BD:E0:4D:82:D1:8E=bcqGmaMSP=192.168.0.16=1440 9F:53:D9:17:4E:06=lJujxAzHe=192.168.0.17=1440 79:F3:07:D9:69:30=oIcqN=192.168.0.18=1440 49:FB:D4:AA:0A:0B=HFGJPW=192.168.0.19=1440 84:2C:F8:4F:26:E6=QJyNHnM=192.168.0.20=1440 BD:54:4A:F8:6F:21=ZxNeOCmfQ=192.168.0.21=1440 8D:4D:BC:92:C1:BD=OaMYUo=192.168.0.22=1440 B1:3E:2E:D7:55:EC=enpW=192.168.0.23=1440 15:55:AD:83:79:5B=zcnktlj=192.168.0.24=1440 05:47:4B:16:7B:B5=dHMXslJ=192.168.0.25=1440 3C:EB:57:06:8B:C0=ktwBTWFI=192.168.0.26=1440 97:E4:42:BA:27:0F=MgnHF=192.168.0.27=1440 8D:B8:3D:4B:F7:67=VFfXTH=192.168.0.28=1440 49:18:D0:A8:8E:F2=JnCOzm=192.168.0.29=1440 CF:CE:63:CB:4C:06=YAEBJzaPdl=192.168.0.30=1440 43:E1:7E:A9:58:94=gJmHPo=192.168.0.31=1440 CE:CC:9A:68:08:B8=oiFzC=192.168.0.32=1440 ED:AB:20:91:4B:3F=ZAcgWwsY=192.168.0.33=1440 A6:EF:DD:60:9A:40=ansiZ=192.168.0.34=1440 7E:0E:0F:7F:F4:9F=rvJf=192.168.0.35=1440 3A:9D:95:21:BA:43=NjXMRTW=192.168.0.36=1440 B7:B4:7E:1C:04:BE=vMzVq=192.168.0.37=1440 C2:49:BB:82:02:A2=NYptZcWBHo=192.168.0.38=1440 3D:26:5D:42:91:3F=KpWxe=192.168.0.39=1440 81:67:FF:FD:AB:60=SVpRvIl=192.168.0.40=1440 78:CE:DF:86:AE:A9=rVBv=192.168.0.41=1440 03:8E:E4:08:39:0E=YrUbFEk=192.168.0.183=1440 E8:96:FE:08:82:F0=QkChN=192.168.0.103=1440 53:5F:F7:11:38:1E=WwRhy=192.168.0.192=1440 EB:BF:B7:B7:6E:71=vESR=192.168.0.200=1440 E5:3B:F3:1D:32:66=sSwpycbOa=192.168.0.210=1440 7D:A6:13:0F:DF:3D=LAbwKS=192.168.0.225=1440 8E:34:32:C9:E8:5A=SYUNe=192.168.0.243=1440 5B:92:24:9F:01:EB=muYhDI=192.168.0.232=14''';

    String badDdWrt3 =
        '''
C4:4D:02:A0:E1:96=WHis= 7F:B7:26:C3:A8:D3=FxwzLDsBK=192.168.0.4=1440 FC:D6:B5:48:65:3D=agXCrZIQT=192.168.0.5=1440 F4:34:E2:3A:F9:30=umTiNUO=192.168.0.6=1440 89:2A:F0:C5:2A:30=KnOtLxjPCm=192.168.0.7=1440 A1:C6:4E:4A:E6:96=EfnktBOZWh=192.168.0.8=1440 D1:F4:18:48:A9:C0=vAYoTegH=192.168.0.9=1440 56:A5:2B:40:39:7F=mgeLTnQV=192.168.0.10=1440 28:5B:98:CD:B5:34=vlrZbMUO=192.168.0.11=1440 61:88:68:5E:86:7A=gfrM=192.168.0.12=1440 90:69:74:25:F0:49=CQvAEsca=192.168.0.13=1440 D6:55:91:F0:F2:89=EBknxyhwO=192.168.0.14=1440 90:83:FA:69:F2:74=GxhW=192.168.0.15=1440 BD:E0:4D:82:D1:8E=bcqGmaMSP=192.168.0.16=1440 9F:53:D9:17:4E:06=lJujxAzHe=192.168.0.17=1440 79:F3:07:D9:69:30=oIcqN=192.168.0.18=1440 49:FB:D4:AA:0A:0B=HFGJPW=192.168.0.19=1440 84:2C:F8:4F:26:E6=QJyNHnM=192.168.0.20=1440 BD:54:4A:F8:6F:21=ZxNeOCmfQ=192.168.0.21=1440 8D:4D:BC:92:C1:BD=OaMYUo=192.168.0.22=1440 B1:3E:2E:D7:55:EC=enpW=192.168.0.23=1440 15:55:AD:83:79:5B=zcnktlj=192.168.0.24=1440 05:47:4B:16:7B:B5=dHMXslJ=192.168.0.25=1440 3C:EB:57:06:8B:C0=ktwBTWFI=192.168.0.26=1440 97:E4:42:BA:27:0F=MgnHF=192.168.0.27=1440 8D:B8:3D:4B:F7:67=VFfXTH=192.168.0.28=1440 49:18:D0:A8:8E:F2=JnCOzm=192.168.0.29=1440 CF:CE:63:CB:4C:06=YAEBJzaPdl=192.168.0.30=1440 43:E1:7E:A9:58:94=gJmHPo=192.168.0.31=1440 CE:CC:9A:68:08:B8=oiFzC=192.168.0.32=1440 ED:AB:20:91:4B:3F=ZAcgWwsY=192.168.0.33=1440 A6:EF:DD:60:9A:40=ansiZ=192.168.0.34=1440 7E:0E:0F:7F:F4:9F=rvJf=192.168.0.35=1440 3A:9D:95:21:BA:43=NjXMRTW=192.168.0.36=1440 B7:B4:7E:1C:04:BE=vMzVq=192.168.0.37=1440 C2:49:BB:82:02:A2=NYptZcWBHo=192.168.0.38=1440 3D:26:5D:42:91:3F=KpWxe=192.168.0.39=1440 81:67:FF:FD:AB:60=SVpRvIl=192.168.0.40=1440 78:CE:DF:86:AE:A9=rVBv=192.168.0.41=1440 03:8E:E4:08:39:0E=YrUbFEk=192.168.0.183=1440 E8:96:FE:08:82:F0=QkChN=192.168.0.103=1440 53:5F:F7:11:38:1E=WwRhy=192.168.0.192=1440 EB:BF:B7:B7:6E:71=vESR=192.168.0.200=1440 E5:3B:F3:1D:32:66=sSwpycbOa=192.168.0.210=1440 7D:A6:13:0F:DF:3D=LAbwKS=192.168.0.225=1440 8E:34:32:C9:E8:5A=SYUNe=192.168.0.243=1440 5B:92:24:9F:01:EB=muYhDI=192.168.0.232=1440''';
    expect(ddwrt.isFileValid("test/test-output/test-output-file.ddwrt"), true);
    expect(ddwrt.isFileValid("test/test-data/lease-list-infile.ddwrt"), true);
    expect(ddwrt.isFileValid("test/test-data/lease-list-infile.json"), false);
    expect(ddwrt.isContentValid(fileContents: goodDdWrt), true);
    expect(ddwrt.isContentValid(fileContents: badDdWrt), false);
    expect(ddwrt.isContentValid(fileContents: badDdWrt2), false);
    expect(ddwrt.isContentValid(fileContents: badDdWrt3), false);
    expect(ddwrt.isContentValid(fileContents: ""), false);
  });

  test('isCSV', () {
    Csv csv = Csv();

    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "c",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    expect(csv.isFileValid("test/test-data/lease-list-infile.csv"), true);
    expect(csv.isFileValid("test/test-output/test-output-file.csv"), true);

    expect(csv.isFileValid("test/test-data/lease-list-infile.ddwrt"), false);
    expect(
        csv.isContentValid(
            fileContents:
                """
            host-name,mac-address,address
            sbBjvPlVX,7F:5D:E0:9F:3D:00,192.168.0.233
            ZVdfiSQ,30:7C:6C:27:D9:8D,192.168.0.253
            IyPaYwzKNk,AF:17:50:02:F8:0A,192.168.0.240
            """),
        true);
    expect(
        csv.isContentValid(
            fileContents: '{"hostname, macaddress, address, value"}'),
        false);
    expect(
        csv.isContentValid(
            fileContents:
                """
            host-name,mac-address,address
            sbBjvPlVX,7F:5D:E0:9F:3D:00,192.168.0.233
            ZVdfiSQ,30:7C:6C:27:D98D,192.168.0.253
            IyPaYwzKNk,AF:17:50:02:F8:0A,192.168.0.240
            """),
        false);
    expect(
        csv.isContentValid(
            fileContents:
                """
            host-name,macaddress,address
            sbBjvPlVX,7F:5D:E0:9F:3D:00,192.168.0.233
            ZVdfiSQ,30:7C:6C:27:D9:8D,192.168.0.253
            IyPaYwzKNk,AF:17:50:02:F8:0A,192.168.0.240
            """),
        false);
  });
  test('opnSense', () {
    OpnSense opnSense = OpnSense();

    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "n",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file-opn",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    String goodOpnsense =
        """<?xml version="1.0"?>
<opnsense>
<dhcpd>
    <lan>
      <enable>1</enable>
      <ddnsdomainalgorithm>hmac-md5</ddnsdomainalgorithm>
      <numberoptions>
        <item/>
      </numberoptions>
      <range>
        <from>192.168.0.1</from>
        <to>192.168.0.254</to>
      </range>
      <winsserver/>
      <dnsserver/>
      <ntpserver/>
      <staticmap>
        <mac>00:22:1d:d3:a0:d2</mac>
        <ipaddr>192.168.0.3</ipaddr>
        <hostname>hostnameExample1</hostname>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
      <staticmap>
        <mac>00:14:1e:d2:b0:c2</mac>
        <ipaddr>192.168.0.4</ipaddr>
        <hostname>hostnameExample2</hostname>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
            <staticmap>
        <mac>00:35:1e:d3:b1:c5</mac>
        <ipaddr>192.168.0.5</ipaddr>
        <hostname>hostnameExample3</hostname>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
    </lan>  
  </dhcpd>
  </opnsense>
   """;

    String badOpnsense =
        """
<?xml version="1.0"?>
<opnsense>
<dhcpd>
    <lan>
      <enable>1</enable>
      <ddnsdomainalgorithm>hmac-md5</ddnsdomainalgorithm>
      <numberoptions>
        <item/>
      </numberoptions>
      <range>
        <from>192.168.1.2</from>
        <to>192.168.1.254</to>
      </range>
      <winsserver/>
      <dnsserver/>
      <ntpserver/>
      <staticmap>
        <mac>00:22:1d:d3:a0:d2</mac>
        <ipaddr>192.168.1.3</ipaddr>
        <hostname>hostnameExample</hostname>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
      <staticmap>
        <mac>00:14:1e:d2:b0:c2</mac>
        <ipaddr>192.168.1.4</ipaddr>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
            <staticmap>
        <mac>00:35:1e:d3:b1:c5</mac>
        <ipaddr>192.168.1.5</ipaddr>
        <winsserver/>
        <dnsserver/>
        <ntpserver/>
      </staticmap>
    </lan>  
  <dhcpd>
  </opnsense>
   """;

    expect(
        opnSense.isFileValid(
          "test/test-output/test-output-file-opn.xml",
        ),
        true);
    expect(
        opnSense.isFileValid("test/test-data/lease-list-infile-opn.xml"), true);
    expect(
        opnSense.isFileValid("test/test-data/lease-list-infile.json"), false);
    expect(opnSense.isContentValid(fileContents: badOpnsense), false);

    expect(opnSense.isContentValid(fileContents: goodOpnsense), true);
  });

  test('pfSense', () {
    PfSense pfSense = PfSense();

    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.json",
      "-t",
      "j",
      "-g",
      "p",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file-pfs",
      "-d",
      "test/test-output",
      "-w"
    ];
    upRoot(args);

    String goodPfsense =
        """
<dhcpd>
	<lan>
		<range>
			<from>192.168.0.1</from>
			<to>192.168.0.254</to>
		</range>
		<staticmap>
			<mac>04:00:23:7e:34:c1</mac>
			<cid></cid>
			<ipaddr>192.168.0.4</ipaddr>
			<hostname>ExampleHostName</hostname>
			<descr></descr>
			<filename></filename>
			<rootpath></rootpath>
			<defaultleasetime></defaultleasetime>
			<maxleasetime></maxleasetime>
			<gateway></gateway>
			<domain></domain>
			<domainsearchlist></domainsearchlist>
			<ddnsdomain></ddnsdomain>
			<ddnsdomainprimary></ddnsdomainprimary>
			<ddnsdomainsecondary></ddnsdomainsecondary>
			<ddnsdomainkeyname></ddnsdomainkeyname>
			<ddnsdomainkeyalgorithm>hmac-md5</ddnsdomainkeyalgorithm>
			<ddnsdomainkey></ddnsdomainkey>
			<tftp></tftp>
			<ldap></ldap>
			<nextserver></nextserver>
			<filename32></filename32>
			<filename64></filename64>
			<filename32arm></filename32arm>
			<filename64arm></filename64arm>
			<numberoptions></numberoptions>
		</staticmap>
		<enable></enable>
	</lan>
</dhcpd>
   """;

    String badPfsense =
        """
<dhcpd>
	<lan>
		<range>
			<from>192.168.0.1</from>
			<to>192.168.0.254</to>
		</range>
		<staticmap>
			<mac>04:00:23:7e:34:c1</mac>
			<cid></cid>
			<ipaddr></ipaddr>
			<hostname>ExampleHostName</hostname>
			<descr></descr>
			<filename></filename>
			<rootpath></rootpath>
			<defaultleasetime></defaultleasetime>
			<maxleasetime></maxleasetime>
			<gateway></gateway>
			<domain></domain>
			<domainsearchlist></domainsearchlist>
			<ddnsdomain></ddnsdomain>
			<ddnsdomainprimary></ddnsdomainprimary>
			<ddnsdomainsecondary></ddnsdomainsecondary>
			<ddnsdomainkeyname></ddnsdomainkeyname>
			<ddnsdomainkeyalgorithm>hmac-md5</ddnsdomainkeyalgorithm>
			<ddnsdomainkey></ddnsdomainkey>
			<tftp></tftp>
			<ldap></ldap>
			<nextserver></nextserver>
			<filename32></filename32>
			<filename64></filename64>
			<filename32arm></filename32arm>
			<filename64arm></filename64arm>
			<numberoptions></numberoptions>
		</staticmap>
		<enable></enable>
	</lan>
</dhcpd>
   """;

    expect(
        pfSense.isFileValid(
          "test/test-output/test-output-file-pfs.xml",
        ),
        true);
    expect(
        pfSense.isFileValid("test/test-data/lease-list-infile-pfs.xml"), true);
    expect(pfSense.isFileValid("test/test-data/lease-list-infile.json"), false);
    expect(pfSense.isContentValid(fileContents: badPfsense), false);

    expect(pfSense.isContentValid(fileContents: goodPfsense), true);
  });

  test('outputLength', () {
    Csv csv = Csv();
    Ddwrt ddwrt = Ddwrt();
    Json json = Json();
    Mikrotik mikrotik = Mikrotik();
    OpenWrt openwrt = OpenWrt();
    PfSense pfsense = PfSense();
    List<String> args = <String>[
      "-i",
      "test/test-data/lease-list-infile.csv",
      "-t",
      "c",
      "-g",
      "j",
      "-L",
      "192.168.0.1",
      "-H",
      "192.168.0.254",
      "-b",
      "test-output-file",
      "-d",
      "test/test-output",
      "-w"
    ];

    argResults = cliArgs.getArgs(args);

    expect(
        isCorrectLeaseMapLength(
            csv.getLease(
                fileContents: File("test/test-output/test-output-file.csv")
                    .readAsStringSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            ddwrt.getLease(
                fileContents: File("test/test-output/test-output-file.ddwrt")
                    .readAsStringSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            json.getLease(
                fileContents: File("test/test-output/test-output-file.json")
                    .readAsStringSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            mikrotik.getLease(
                fileContents: File("test/test-output/test-output-file.rsc")
                    .readAsStringSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            openwrt.getLease(
                fileLines: File("test/test-output/test-output-file.openwrt")
                    .readAsLinesSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            pfsense.getLease(
                fileContents: File("test/test-output/test-output-file-pfs.xml")
                    .readAsStringSync()),
            50),
        true);

    expect(
        isCorrectLeaseMapLength(
            pfsense.getLease(
                fileContents: File("test/test-output/test-output-file-opn.xml")
                    .readAsStringSync()),
            50),
        true);
  });
}

/// Provides match for error message result when testing, argument
/// can be partial match */
Matcher checkErrorMessage(String partialErrMessage) {
  return throwsA(predicate(
      (dynamic e) => e.message.toString().trim().contains(partialErrMessage)));
}
