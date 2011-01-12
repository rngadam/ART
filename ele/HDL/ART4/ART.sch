<?xml version="1.0" encoding="UTF-8"?>
<drawing version="7">
    <attr value="xc9500" name="DeviceFamilyName">
        <trait delete="all:0" />
        <trait editname="all:0" />
        <trait edittrait="all:0" />
    </attr>
    <netlist>
        <signal name="XLXN_150" />
        <signal name="XLXN_159" />
        <signal name="XLXN_164" />
        <signal name="XLXN_168" />
        <signal name="XLXN_169" />
        <signal name="ForwardDir" />
        <signal name="ReverseDir" />
        <signal name="RightDir" />
        <signal name="Right" />
        <signal name="Left" />
        <signal name="Reverse" />
        <signal name="XLXN_238" />
        <signal name="LeftDir" />
        <signal name="XLXN_250" />
        <signal name="XLXN_251" />
        <signal name="UserFunction0" />
        <signal name="UserFunction1" />
        <signal name="XLXN_254" />
        <signal name="XLXN_385" />
        <signal name="XLXN_386" />
        <signal name="XLXN_387" />
        <signal name="DIRSEL0" />
        <signal name="DIRSEL1" />
        <signal name="DIRSEL2" />
        <signal name="XLXN_401" />
        <signal name="XLXN_239" />
        <signal name="XLXN_240" />
        <signal name="XLXN_241" />
        <signal name="XLXN_242" />
        <signal name="TriggerSonar2" />
        <signal name="TriggerSonar3" />
        <signal name="TriggerSonar1" />
        <signal name="TriggerSonar0" />
        <signal name="EchoSonar3" />
        <signal name="EchoSonar2" />
        <signal name="EchoSonar1" />
        <signal name="EchoSonar0" />
        <signal name="XLXN_261" />
        <signal name="XLXN_260" />
        <signal name="XLXN_259" />
        <signal name="XLXN_258" />
        <signal name="XLXN_33" />
        <signal name="XLXN_322" />
        <signal name="EchoSonar" />
        <signal name="TriggerSonar" />
        <signal name="XLXN_340" />
        <signal name="XLXN_423" />
        <signal name="XLXN_396" />
        <signal name="XLXN_398" />
        <signal name="SONARSEL0" />
        <signal name="SONARSEL1" />
        <port polarity="Output" name="ForwardDir" />
        <port polarity="Output" name="ReverseDir" />
        <port polarity="Output" name="RightDir" />
        <port polarity="Output" name="LeftDir" />
        <port polarity="Output" name="UserFunction0" />
        <port polarity="Output" name="UserFunction1" />
        <port polarity="Input" name="DIRSEL0" />
        <port polarity="Input" name="DIRSEL1" />
        <port polarity="Input" name="DIRSEL2" />
        <port polarity="Output" name="TriggerSonar2" />
        <port polarity="Output" name="TriggerSonar3" />
        <port polarity="Output" name="TriggerSonar1" />
        <port polarity="Output" name="TriggerSonar0" />
        <port polarity="Input" name="EchoSonar3" />
        <port polarity="Input" name="EchoSonar2" />
        <port polarity="Input" name="EchoSonar1" />
        <port polarity="Input" name="EchoSonar0" />
        <port polarity="Output" name="EchoSonar" />
        <port polarity="Input" name="TriggerSonar" />
        <port polarity="Input" name="SONARSEL0" />
        <port polarity="Input" name="SONARSEL1" />
        <blockdef name="m4_1e">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="96" y1="-416" y2="-416" x1="0" />
            <line x2="96" y1="-352" y2="-352" x1="0" />
            <line x2="96" y1="-288" y2="-288" x1="0" />
            <line x2="96" y1="-224" y2="-224" x1="0" />
            <line x2="96" y1="-32" y2="-32" x1="0" />
            <line x2="256" y1="-320" y2="-320" x1="320" />
            <line x2="96" y1="-160" y2="-160" x1="0" />
            <line x2="96" y1="-96" y2="-96" x1="0" />
            <line x2="96" y1="-96" y2="-96" x1="176" />
            <line x2="176" y1="-208" y2="-96" x1="176" />
            <line x2="96" y1="-32" y2="-32" x1="224" />
            <line x2="224" y1="-216" y2="-32" x1="224" />
            <line x2="96" y1="-224" y2="-192" x1="256" />
            <line x2="256" y1="-416" y2="-224" x1="256" />
            <line x2="256" y1="-448" y2="-416" x1="96" />
            <line x2="96" y1="-192" y2="-448" x1="96" />
            <line x2="96" y1="-160" y2="-160" x1="128" />
            <line x2="128" y1="-200" y2="-160" x1="128" />
        </blockdef>
        <blockdef name="vcc">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="32" y1="-64" y2="-64" x1="96" />
            <line x2="64" y1="0" y2="-32" x1="64" />
            <line x2="64" y1="-32" y2="-64" x1="64" />
        </blockdef>
        <blockdef name="d2_4e">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <rect width="256" x="64" y="-384" height="320" />
            <line x2="64" y1="-128" y2="-128" x1="0" />
            <line x2="64" y1="-256" y2="-256" x1="0" />
            <line x2="64" y1="-320" y2="-320" x1="0" />
            <line x2="320" y1="-128" y2="-128" x1="384" />
            <line x2="320" y1="-192" y2="-192" x1="384" />
            <line x2="320" y1="-256" y2="-256" x1="384" />
            <line x2="320" y1="-320" y2="-320" x1="384" />
        </blockdef>
        <blockdef name="d3_8e">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="-576" y2="-576" x1="0" />
            <line x2="64" y1="-512" y2="-512" x1="0" />
            <line x2="64" y1="-448" y2="-448" x1="0" />
            <line x2="320" y1="-576" y2="-576" x1="384" />
            <line x2="320" y1="-512" y2="-512" x1="384" />
            <line x2="320" y1="-448" y2="-448" x1="384" />
            <line x2="320" y1="-384" y2="-384" x1="384" />
            <line x2="320" y1="-320" y2="-320" x1="384" />
            <line x2="320" y1="-256" y2="-256" x1="384" />
            <line x2="320" y1="-192" y2="-192" x1="384" />
            <line x2="320" y1="-128" y2="-128" x1="384" />
            <rect width="256" x="64" y="-640" height="576" />
            <line x2="64" y1="-128" y2="-128" x1="0" />
        </blockdef>
        <blockdef name="or3">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="48" y1="-64" y2="-64" x1="0" />
            <line x2="72" y1="-128" y2="-128" x1="0" />
            <line x2="48" y1="-192" y2="-192" x1="0" />
            <line x2="192" y1="-128" y2="-128" x1="256" />
            <arc ex="192" ey="-128" sx="112" sy="-80" r="88" cx="116" cy="-168" />
            <arc ex="48" ey="-176" sx="48" sy="-80" r="56" cx="16" cy="-128" />
            <line x2="48" y1="-64" y2="-80" x1="48" />
            <line x2="48" y1="-192" y2="-176" x1="48" />
            <line x2="48" y1="-80" y2="-80" x1="112" />
            <arc ex="112" ey="-176" sx="192" sy="-128" r="88" cx="116" cy="-88" />
            <line x2="48" y1="-176" y2="-176" x1="112" />
        </blockdef>
        <blockdef name="or2">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="-64" y2="-64" x1="0" />
            <line x2="64" y1="-128" y2="-128" x1="0" />
            <line x2="192" y1="-96" y2="-96" x1="256" />
            <arc ex="192" ey="-96" sx="112" sy="-48" r="88" cx="116" cy="-136" />
            <arc ex="48" ey="-144" sx="48" sy="-48" r="56" cx="16" cy="-96" />
            <line x2="48" y1="-144" y2="-144" x1="112" />
            <arc ex="112" ey="-144" sx="192" sy="-96" r="88" cx="116" cy="-56" />
            <line x2="48" y1="-48" y2="-48" x1="112" />
        </blockdef>
        <blockdef name="obuf">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="0" y2="-64" x1="64" />
            <line x2="64" y1="-32" y2="0" x1="128" />
            <line x2="128" y1="-64" y2="-32" x1="64" />
            <line x2="64" y1="-32" y2="-32" x1="0" />
            <line x2="128" y1="-32" y2="-32" x1="224" />
        </blockdef>
        <blockdef name="obuf4">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="0" y2="-64" x1="64" />
            <line x2="64" y1="-32" y2="0" x1="128" />
            <line x2="128" y1="-64" y2="-32" x1="64" />
            <line x2="64" y1="-128" y2="-192" x1="64" />
            <line x2="64" y1="-160" y2="-128" x1="128" />
            <line x2="128" y1="-192" y2="-160" x1="64" />
            <line x2="64" y1="-192" y2="-256" x1="64" />
            <line x2="64" y1="-224" y2="-192" x1="128" />
            <line x2="128" y1="-256" y2="-224" x1="64" />
            <line x2="128" y1="-224" y2="-224" x1="224" />
            <line x2="128" y1="-160" y2="-160" x1="224" />
            <line x2="64" y1="-96" y2="-96" x1="0" />
            <line x2="128" y1="-96" y2="-96" x1="224" />
            <line x2="64" y1="-64" y2="-128" x1="64" />
            <line x2="64" y1="-96" y2="-64" x1="128" />
            <line x2="128" y1="-128" y2="-96" x1="64" />
            <line x2="64" y1="-160" y2="-160" x1="0" />
            <line x2="64" y1="-224" y2="-224" x1="0" />
            <line x2="64" y1="-32" y2="-32" x1="0" />
            <line x2="128" y1="-32" y2="-32" x1="224" />
        </blockdef>
        <blockdef name="ibuf4">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="-224" y2="-224" x1="0" />
            <line x2="128" y1="-160" y2="-160" x1="224" />
            <line x2="64" y1="-32" y2="-32" x1="0" />
            <line x2="64" y1="-192" y2="-256" x1="64" />
            <line x2="64" y1="-224" y2="-192" x1="128" />
            <line x2="128" y1="-256" y2="-224" x1="64" />
            <line x2="64" y1="-128" y2="-192" x1="64" />
            <line x2="64" y1="-160" y2="-128" x1="128" />
            <line x2="128" y1="-192" y2="-160" x1="64" />
            <line x2="64" y1="-64" y2="-128" x1="64" />
            <line x2="64" y1="-96" y2="-64" x1="128" />
            <line x2="128" y1="-128" y2="-96" x1="64" />
            <line x2="64" y1="0" y2="-64" x1="64" />
            <line x2="64" y1="-32" y2="0" x1="128" />
            <line x2="128" y1="-64" y2="-32" x1="64" />
            <line x2="128" y1="-32" y2="-32" x1="224" />
            <line x2="64" y1="-96" y2="-96" x1="0" />
            <line x2="64" y1="-160" y2="-160" x1="0" />
            <line x2="128" y1="-224" y2="-224" x1="224" />
            <line x2="128" y1="-96" y2="-96" x1="224" />
        </blockdef>
        <blockdef name="ibuf">
            <timestamp>2000-1-1T10:10:10</timestamp>
            <line x2="64" y1="0" y2="-64" x1="64" />
            <line x2="64" y1="-32" y2="0" x1="128" />
            <line x2="128" y1="-64" y2="-32" x1="64" />
            <line x2="128" y1="-32" y2="-32" x1="224" />
            <line x2="64" y1="-32" y2="-32" x1="0" />
        </blockdef>
        <blockdef name="copy_of_title">
            <timestamp>2011-1-7T15:56:31</timestamp>
            <line x2="-1140" y1="-176" y2="-176" x1="-112" />
            <line x2="-1136" y1="-416" y2="-212" style="linewidth:W" x1="-1136" />
            <line x2="-80" y1="-416" y2="-220" style="linewidth:W" x1="-80" />
            <line x2="-80" y1="-416" y2="-416" style="linewidth:W" x1="-1136" />
            <line x2="-80" y1="-128" y2="-128" x1="-1136" />
            <line x2="-80" y1="-220" y2="-220" x1="-1132" />
            <line x2="-352" y1="-80" y2="-80" style="linewidth:W" x1="-80" />
            <line x2="-352" y1="-80" y2="-80" style="linewidth:W" x1="-1136" />
            <line x2="-1136" y1="-224" y2="-80" style="linewidth:W" x1="-1136" />
            <line x2="-152" y1="-80" y2="-80" style="linewidth:W" x1="-144" />
            <line x2="-80" y1="-224" y2="-80" style="linewidth:W" x1="-80" />
            <line x2="-780" y1="-128" y2="-80" x1="-780" />
            <line x2="-80" y1="-176" y2="-176" x1="-112" />
            <line x2="-144" y1="-128" y2="-128" x1="-176" />
            <line x2="-920" y1="-360" y2="-364" x1="-840" />
            <arc ex="-816" ey="-252" sx="-924" sy="-260" r="72" cx="-867" cy="-306" />
            <line x2="-924" y1="-264" y2="-260" x1="-844" />
            <line x2="-844" y1="-304" y2="-264" x1="-808" />
            <line x2="-840" y1="-304" y2="-360" x1="-808" />
            <line x2="-816" y1="-296" y2="-360" x1="-628" />
            <line x2="-632" y1="-252" y2="-264" x1="-816" />
            <arc ex="-976" ey="-300" sx="-936" sy="-380" r="46" cx="-944" cy="-334" />
            <arc ex="-972" ey="-264" sx="-920" sy="-396" r="70" cx="-948" cy="-331" />
            <line x2="-628" y1="-264" y2="-296" x1="-632" />
            <arc ex="-920" ey="-364" sx="-816" sy="-360" r="53" cx="-869" cy="-346" />
            <rect width="40" x="-904" y="-332" height="40" />
            <line x2="-836" y1="-328" y2="-328" x1="-860" />
            <line x2="-836" y1="-312" y2="-312" x1="-860" />
            <line x2="-836" y1="-296" y2="-296" x1="-860" />
            <line x2="-900" y1="-268" y2="-288" x1="-900" />
            <line x2="-884" y1="-268" y2="-288" x1="-884" />
            <line x2="-868" y1="-268" y2="-288" x1="-868" />
            <line x2="-904" y1="-328" y2="-328" x1="-928" />
            <line x2="-904" y1="-312" y2="-312" x1="-928" />
            <line x2="-904" y1="-296" y2="-296" x1="-928" />
            <line x2="-900" y1="-332" y2="-352" x1="-900" />
            <line x2="-884" y1="-332" y2="-352" x1="-884" />
            <line x2="-868" y1="-332" y2="-352" x1="-868" />
        </blockdef>
        <block symbolname="vcc" name="XLXI_40">
            <blockpin signalname="XLXN_150" name="P" />
        </block>
        <block symbolname="or3" name="XLXI_13">
            <blockpin signalname="XLXN_168" name="I0" />
            <blockpin signalname="XLXN_238" name="I1" />
            <blockpin signalname="XLXN_159" name="I2" />
            <blockpin signalname="XLXN_254" name="O" />
        </block>
        <block symbolname="or3" name="XLXI_14">
            <blockpin signalname="XLXN_169" name="I0" />
            <blockpin signalname="XLXN_401" name="I1" />
            <blockpin signalname="XLXN_164" name="I2" />
            <blockpin signalname="Reverse" name="O" />
        </block>
        <block symbolname="or2" name="XLXI_39">
            <blockpin signalname="XLXN_169" name="I0" />
            <blockpin signalname="XLXN_168" name="I1" />
            <blockpin signalname="Right" name="O" />
        </block>
        <block symbolname="or2" name="XLXI_38">
            <blockpin signalname="XLXN_401" name="I0" />
            <blockpin signalname="XLXN_238" name="I1" />
            <blockpin signalname="Left" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_49">
            <blockpin signalname="Reverse" name="I" />
            <blockpin signalname="ReverseDir" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_51">
            <blockpin signalname="Right" name="I" />
            <blockpin signalname="RightDir" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_44">
            <blockpin signalname="XLXN_254" name="I" />
            <blockpin signalname="ForwardDir" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_47">
            <blockpin signalname="Left" name="I" />
            <blockpin signalname="LeftDir" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_54">
            <blockpin signalname="XLXN_250" name="I" />
            <blockpin signalname="UserFunction1" name="O" />
        </block>
        <block symbolname="obuf" name="XLXI_55">
            <blockpin signalname="XLXN_251" name="I" />
            <blockpin signalname="UserFunction0" name="O" />
        </block>
        <block symbolname="d3_8e" name="XLXI_12">
            <blockpin signalname="XLXN_385" name="A0" />
            <blockpin signalname="XLXN_386" name="A1" />
            <blockpin signalname="XLXN_387" name="A2" />
            <blockpin signalname="XLXN_150" name="E" />
            <blockpin signalname="XLXN_251" name="D0" />
            <blockpin signalname="XLXN_250" name="D1" />
            <blockpin signalname="XLXN_159" name="D2" />
            <blockpin signalname="XLXN_238" name="D3" />
            <blockpin signalname="XLXN_168" name="D4" />
            <blockpin signalname="XLXN_164" name="D5" />
            <blockpin signalname="XLXN_401" name="D6" />
            <blockpin signalname="XLXN_169" name="D7" />
        </block>
        <block symbolname="ibuf" name="XLXI_102">
            <blockpin signalname="DIRSEL0" name="I" />
            <blockpin signalname="XLXN_385" name="O" />
        </block>
        <block symbolname="ibuf" name="XLXI_103">
            <blockpin signalname="DIRSEL1" name="I" />
            <blockpin signalname="XLXN_386" name="O" />
        </block>
        <block symbolname="ibuf" name="XLXI_104">
            <blockpin signalname="DIRSEL2" name="I" />
            <blockpin signalname="XLXN_387" name="O" />
        </block>
        <block symbolname="copy_of_title" name="XLXI_115" />
        <block symbolname="d2_4e" name="XLXI_9">
            <blockpin signalname="XLXN_396" name="A0" />
            <blockpin signalname="XLXN_398" name="A1" />
            <blockpin signalname="XLXN_340" name="E" />
            <blockpin signalname="XLXN_239" name="D0" />
            <blockpin signalname="XLXN_240" name="D1" />
            <blockpin signalname="XLXN_241" name="D2" />
            <blockpin signalname="XLXN_242" name="D3" />
        </block>
        <block symbolname="obuf4" name="XLXI_53">
            <blockpin signalname="XLXN_239" name="I0" />
            <blockpin signalname="XLXN_240" name="I1" />
            <blockpin signalname="XLXN_241" name="I2" />
            <blockpin signalname="XLXN_242" name="I3" />
            <blockpin signalname="TriggerSonar0" name="O0" />
            <blockpin signalname="TriggerSonar1" name="O1" />
            <blockpin signalname="TriggerSonar2" name="O2" />
            <blockpin signalname="TriggerSonar3" name="O3" />
        </block>
        <block symbolname="ibuf4" name="XLXI_59">
            <blockpin signalname="EchoSonar3" name="I0" />
            <blockpin signalname="EchoSonar2" name="I1" />
            <blockpin signalname="EchoSonar1" name="I2" />
            <blockpin signalname="EchoSonar0" name="I3" />
            <blockpin signalname="XLXN_261" name="O0" />
            <blockpin signalname="XLXN_260" name="O1" />
            <blockpin signalname="XLXN_259" name="O2" />
            <blockpin signalname="XLXN_258" name="O3" />
        </block>
        <block symbolname="vcc" name="XLXI_6">
            <blockpin signalname="XLXN_33" name="P" />
        </block>
        <block symbolname="obuf" name="XLXI_72">
            <blockpin signalname="XLXN_322" name="I" />
            <blockpin signalname="EchoSonar" name="O" />
        </block>
        <block symbolname="m4_1e" name="XLXI_2">
            <blockpin signalname="XLXN_258" name="D0" />
            <blockpin signalname="XLXN_259" name="D1" />
            <blockpin signalname="XLXN_260" name="D2" />
            <blockpin signalname="XLXN_261" name="D3" />
            <blockpin signalname="XLXN_33" name="E" />
            <blockpin signalname="XLXN_396" name="S0" />
            <blockpin signalname="XLXN_398" name="S1" />
            <blockpin signalname="XLXN_322" name="O" />
        </block>
        <block symbolname="ibuf" name="XLXI_77">
            <blockpin signalname="TriggerSonar" name="I" />
            <blockpin signalname="XLXN_340" name="O" />
        </block>
        <block symbolname="ibuf" name="XLXI_110">
            <blockpin signalname="SONARSEL0" name="I" />
            <blockpin signalname="XLXN_396" name="O" />
        </block>
        <block symbolname="ibuf" name="XLXI_111">
            <blockpin signalname="SONARSEL1" name="I" />
            <blockpin signalname="XLXN_398" name="O" />
        </block>
    </netlist>
    <sheet sheetnum="1" width="3520" height="2720">
        <branch name="XLXN_150">
            <wire x2="512" y1="2192" y2="2256" x1="512" />
            <wire x2="608" y1="2256" y2="2256" x1="512" />
            <wire x2="608" y1="2176" y2="2256" x1="608" />
            <wire x2="656" y1="2176" y2="2176" x1="608" />
        </branch>
        <branch name="XLXN_159">
            <wire x2="1104" y1="1856" y2="1856" x1="1040" />
        </branch>
        <branch name="XLXN_164">
            <wire x2="1088" y1="2048" y2="2048" x1="1040" />
        </branch>
        <branch name="XLXN_168">
            <wire x2="1072" y1="1984" y2="1984" x1="1040" />
            <wire x2="1104" y1="1984" y2="1984" x1="1072" />
            <wire x2="1072" y1="1984" y2="2240" x1="1072" />
            <wire x2="1184" y1="2240" y2="2240" x1="1072" />
        </branch>
        <branch name="XLXN_169">
            <wire x2="1056" y1="2176" y2="2176" x1="1040" />
            <wire x2="1088" y1="2176" y2="2176" x1="1056" />
            <wire x2="1056" y1="2176" y2="2304" x1="1056" />
            <wire x2="1184" y1="2304" y2="2304" x1="1056" />
        </branch>
        <branch name="ForwardDir">
            <wire x2="2176" y1="1920" y2="1920" x1="1776" />
        </branch>
        <branch name="ReverseDir">
            <wire x2="2176" y1="2112" y2="2112" x1="1808" />
        </branch>
        <branch name="RightDir">
            <wire x2="2176" y1="2272" y2="2272" x1="1904" />
        </branch>
        <branch name="Right">
            <wire x2="1680" y1="2272" y2="2272" x1="1440" />
        </branch>
        <branch name="Left">
            <wire x2="1920" y1="2000" y2="2000" x1="1760" />
        </branch>
        <branch name="Reverse">
            <wire x2="1584" y1="2112" y2="2112" x1="1344" />
        </branch>
        <branch name="XLXN_238">
            <wire x2="1056" y1="1920" y2="1920" x1="1040" />
            <wire x2="1104" y1="1920" y2="1920" x1="1056" />
            <wire x2="1056" y1="1840" y2="1920" x1="1056" />
            <wire x2="1456" y1="1840" y2="1840" x1="1056" />
            <wire x2="1456" y1="1840" y2="1968" x1="1456" />
            <wire x2="1504" y1="1968" y2="1968" x1="1456" />
        </branch>
        <branch name="LeftDir">
            <wire x2="2176" y1="2000" y2="2000" x1="2144" />
        </branch>
        <branch name="XLXN_250">
            <wire x2="1072" y1="1792" y2="1792" x1="1040" />
        </branch>
        <branch name="XLXN_251">
            <wire x2="1072" y1="1728" y2="1728" x1="1040" />
        </branch>
        <branch name="UserFunction0">
            <wire x2="2176" y1="1728" y2="1728" x1="1296" />
        </branch>
        <branch name="UserFunction1">
            <wire x2="2176" y1="1792" y2="1792" x1="1296" />
        </branch>
        <branch name="XLXN_254">
            <wire x2="1552" y1="1920" y2="1920" x1="1360" />
        </branch>
        <instance x="448" y="2192" name="XLXI_40" orien="R0" />
        <instance x="1104" y="2048" name="XLXI_13" orien="R0" />
        <instance x="1088" y="2240" name="XLXI_14" orien="R0" />
        <text style="fontsize:64;fontname:Arial" x="736" y="2468">Direction Selection</text>
        <instance x="1184" y="2368" name="XLXI_39" orien="R0" />
        <instance x="1504" y="2096" name="XLXI_38" orien="R0" />
        <instance x="1584" y="2144" name="XLXI_49" orien="R0" />
        <instance x="1680" y="2304" name="XLXI_51" orien="R0" />
        <instance x="1552" y="1952" name="XLXI_44" orien="R0" />
        <instance x="1920" y="2032" name="XLXI_47" orien="R0" />
        <instance x="1072" y="1824" name="XLXI_54" orien="R0" />
        <instance x="1072" y="1760" name="XLXI_55" orien="R0" />
        <instance x="656" y="2304" name="XLXI_12" orien="R0" />
        <iomarker fontsize="28" x="2176" y="2000" name="LeftDir" orien="R0" />
        <iomarker fontsize="28" x="2176" y="1728" name="UserFunction0" orien="R0" />
        <iomarker fontsize="28" x="2176" y="1792" name="UserFunction1" orien="R0" />
        <iomarker fontsize="28" x="2176" y="1920" name="ForwardDir" orien="R0" />
        <iomarker fontsize="28" x="2176" y="2112" name="ReverseDir" orien="R0" />
        <iomarker fontsize="28" x="2176" y="2272" name="RightDir" orien="R0" />
        <iomarker fontsize="28" x="336" y="1728" name="DIRSEL0" orien="R180" />
        <iomarker fontsize="28" x="336" y="1792" name="DIRSEL1" orien="R180" />
        <iomarker fontsize="28" x="336" y="1856" name="DIRSEL2" orien="R180" />
        <branch name="XLXN_385">
            <wire x2="656" y1="1728" y2="1728" x1="624" />
        </branch>
        <instance x="400" y="1760" name="XLXI_102" orien="R0" />
        <branch name="XLXN_386">
            <wire x2="656" y1="1792" y2="1792" x1="624" />
        </branch>
        <instance x="400" y="1824" name="XLXI_103" orien="R0" />
        <branch name="XLXN_387">
            <wire x2="656" y1="1856" y2="1856" x1="624" />
        </branch>
        <instance x="400" y="1888" name="XLXI_104" orien="R0" />
        <branch name="DIRSEL0">
            <wire x2="400" y1="1728" y2="1728" x1="336" />
        </branch>
        <branch name="DIRSEL1">
            <wire x2="400" y1="1792" y2="1792" x1="336" />
        </branch>
        <branch name="DIRSEL2">
            <wire x2="400" y1="1856" y2="1856" x1="336" />
        </branch>
        <branch name="XLXN_401">
            <wire x2="1056" y1="2112" y2="2112" x1="1040" />
            <wire x2="1088" y1="2112" y2="2112" x1="1056" />
            <wire x2="1504" y1="2032" y2="2032" x1="1056" />
            <wire x2="1056" y1="2032" y2="2112" x1="1056" />
        </branch>
        <instance x="3520" y="2672" name="XLXI_115" orien="R0">
        </instance>
        <instance x="640" y="592" name="XLXI_9" orien="R0" />
        <branch name="XLXN_239">
            <wire x2="1056" y1="272" y2="272" x1="1024" />
        </branch>
        <branch name="XLXN_240">
            <wire x2="1056" y1="336" y2="336" x1="1024" />
        </branch>
        <branch name="XLXN_241">
            <wire x2="1056" y1="400" y2="400" x1="1024" />
        </branch>
        <branch name="XLXN_242">
            <wire x2="1056" y1="464" y2="464" x1="1024" />
        </branch>
        <instance x="1056" y="496" name="XLXI_53" orien="R0" />
        <branch name="TriggerSonar2">
            <wire x2="1312" y1="400" y2="400" x1="1280" />
        </branch>
        <branch name="TriggerSonar3">
            <wire x2="1312" y1="464" y2="464" x1="1280" />
        </branch>
        <branch name="TriggerSonar1">
            <wire x2="1312" y1="336" y2="336" x1="1280" />
        </branch>
        <branch name="TriggerSonar0">
            <wire x2="1312" y1="272" y2="272" x1="1280" />
        </branch>
        <branch name="EchoSonar3">
            <wire x2="1440" y1="1104" y2="1104" x1="1360" />
        </branch>
        <branch name="EchoSonar2">
            <wire x2="1440" y1="1040" y2="1040" x1="1360" />
        </branch>
        <branch name="EchoSonar1">
            <wire x2="1440" y1="976" y2="976" x1="1360" />
        </branch>
        <branch name="EchoSonar0">
            <wire x2="1440" y1="912" y2="912" x1="1360" />
        </branch>
        <branch name="XLXN_261">
            <wire x2="1136" y1="1104" y2="1104" x1="1056" />
        </branch>
        <branch name="XLXN_260">
            <wire x2="1136" y1="1040" y2="1040" x1="1056" />
        </branch>
        <branch name="XLXN_259">
            <wire x2="1136" y1="976" y2="976" x1="1056" />
        </branch>
        <branch name="XLXN_258">
            <wire x2="1136" y1="912" y2="912" x1="1056" />
        </branch>
        <branch name="XLXN_33">
            <wire x2="1296" y1="1296" y2="1296" x1="1056" />
        </branch>
        <branch name="XLXN_322">
            <wire x2="736" y1="1008" y2="1008" x1="720" />
        </branch>
        <branch name="EchoSonar">
            <wire x2="496" y1="1008" y2="1008" x1="368" />
        </branch>
        <instance x="1360" y="880" name="XLXI_59" orien="R180" />
        <instance x="1296" y="1232" name="XLXI_6" orien="R90" />
        <instance x="720" y="976" name="XLXI_72" orien="R180" />
        <instance x="1056" y="1328" name="XLXI_2" orien="M0" />
        <branch name="TriggerSonar">
            <wire x2="384" y1="464" y2="464" x1="368" />
        </branch>
        <instance x="384" y="496" name="XLXI_77" orien="R0" />
        <branch name="XLXN_340">
            <wire x2="640" y1="464" y2="464" x1="608" />
        </branch>
        <branch name="XLXN_396">
            <wire x2="576" y1="144" y2="272" x1="576" />
            <wire x2="640" y1="272" y2="272" x1="576" />
            <wire x2="1584" y1="144" y2="144" x1="576" />
            <wire x2="1584" y1="144" y2="592" x1="1584" />
            <wire x2="880" y1="592" y2="592" x1="688" />
            <wire x2="1584" y1="592" y2="592" x1="880" />
            <wire x2="880" y1="576" y2="592" x1="880" />
            <wire x2="1120" y1="576" y2="576" x1="880" />
            <wire x2="1120" y1="576" y2="1168" x1="1120" />
            <wire x2="1120" y1="1168" y2="1168" x1="1056" />
        </branch>
        <branch name="XLXN_398">
            <wire x2="592" y1="128" y2="336" x1="592" />
            <wire x2="640" y1="336" y2="336" x1="592" />
            <wire x2="1040" y1="128" y2="128" x1="592" />
            <wire x2="1040" y1="128" y2="720" x1="1040" />
            <wire x2="1072" y1="720" y2="720" x1="1040" />
            <wire x2="1072" y1="720" y2="1232" x1="1072" />
            <wire x2="1040" y1="720" y2="720" x1="688" />
            <wire x2="1072" y1="1232" y2="1232" x1="1056" />
        </branch>
        <branch name="SONARSEL0">
            <wire x2="464" y1="592" y2="592" x1="368" />
        </branch>
        <branch name="SONARSEL1">
            <wire x2="464" y1="720" y2="720" x1="368" />
        </branch>
        <instance x="464" y="624" name="XLXI_110" orien="R0" />
        <instance x="464" y="752" name="XLXI_111" orien="R0" />
        <iomarker fontsize="28" x="1312" y="400" name="TriggerSonar2" orien="R0" />
        <iomarker fontsize="28" x="1312" y="464" name="TriggerSonar3" orien="R0" />
        <iomarker fontsize="28" x="1312" y="336" name="TriggerSonar1" orien="R0" />
        <iomarker fontsize="28" x="1312" y="272" name="TriggerSonar0" orien="R0" />
        <iomarker fontsize="28" x="1440" y="1104" name="EchoSonar3" orien="R0" />
        <iomarker fontsize="28" x="1440" y="1040" name="EchoSonar2" orien="R0" />
        <iomarker fontsize="28" x="1440" y="976" name="EchoSonar1" orien="R0" />
        <iomarker fontsize="28" x="1440" y="912" name="EchoSonar0" orien="R0" />
        <iomarker fontsize="28" x="368" y="464" name="TriggerSonar" orien="R180" />
        <iomarker fontsize="28" x="368" y="720" name="SONARSEL1" orien="R180" />
        <iomarker fontsize="28" x="368" y="1008" name="EchoSonar" orien="R180" />
        <iomarker fontsize="28" x="368" y="592" name="SONARSEL0" orien="R180" />
        <text style="fontsize:64;fontname:Arial" x="720" y="1396">Sensor Selection</text>
    </sheet>
</drawing>