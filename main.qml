import QtQuick 2.9
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.15
//TODO:1指定es 2buffer 3 audio
ApplicationWindow {
    width: 1200
    height: 600
    minimumHeight: 600
    visible: true
    title: qsTr("shadertoy")
    property int channel: 0
    ShaderEffect{
        id: shader
        x:0
        y:0

        width: 640
        height: 360
        property int rotationAngle:0
        property url                    base: "https://www.shadertoy.com/view/?"

        //绕y轴旋转
        transform: Rotation { origin.x: shader.width/2; origin.y: 0; axis { x: 0; y: 1; z: 0 } angle: shader.rotationAngle }
        //绕x轴旋转
        //        transform: Rotation { origin.x: 0; origin.y: shader.height/2; axis { x: 1; y: 0; z: 0 } angle: 120; }
        property var                    iChannel0:image0//
        property var                    iChannel1
        property var                    iChannel2
        property var                    iChannel3
        property real                   iTime: 0
        NumberAnimation on iTime { loops: Animation.Infinite; from: 0; to: Math.PI * 2; duration: 6914/4*4 }
        readonly property vector3d      iResolution: Qt.vector3d(shader.width, shader.height, 0.0)
        property vector4d               iMouse

        //待验证
        property int                    iFrame: 10
        property var                    iChannelTime: [0,1,2,3]
        property var                    iChannelResolution: [Qt.vector3d(shader.width, shader.height, 0.0)]
        property real                   iTimeDelta: 100
        property vector4d               iDate
        property real                   iSampleRate: 4410

        property alias hoverEnabled: mouse.hoverEnabled

        Timer {
            id: timer
            running: true
            interval: 1000
            onTriggered: {
                // 更新 iDate
                var date = new Date();
                shader.iDate.x = date.getFullYear();
                shader.iDate.y = date.getMonth();
                shader.iDate.z = date.getDay();
                shader.iDate.w = date.getSeconds();
            }
        }

        MouseArea {
            id: mouse
            hoverEnabled : true
            anchors.fill: parent
            //hoverEnabled: true
            propagateComposedEvents: true
            onPositionChanged: {
                shader.iMouse.x = mouseX;
                shader.iMouse.y = mouseY;
            }



            onClicked: {
                shader.iMouse.z = mouseX;
                shader.iMouse.w = mouseY;
            }
        }

        vertexShader: "
                    uniform highp mat4 qt_Matrix;
                    attribute highp vec4 qt_Vertex;
                    attribute highp vec2 qt_MultiTexCoord0;
                    varying highp vec2 qt_TexCoord0;
                    void main() {
                        qt_TexCoord0 = qt_MultiTexCoord0;
                       gl_Position = qt_Matrix * qt_Vertex;
                    }"

        readonly property string someDefine: Qt.platform.os === 'osx' ? "":
                                                                        "
            #ifndef GL_ES
            #extension GL_EXT_shader_texture_lod : enable
            #extension GL_OES_standard_derivatives : enable
            precision highp float;
            precision highp int;
            precision mediump sampler2D;
            #endif
            #ifdef GL_ES
            precision mediump float;
            #endif"

        readonly property string
        forwordPixelShaderString:  someDefine +
                                   "
            uniform lowp float qt_Opacity;
            in highp vec2 qt_TexCoord0;
            uniform vec3 iResolution ;
            uniform float iTime;
            uniform float     iChannelTime[4];
            uniform vec3      iChannelResolution[4];
            uniform vec4      iMouse;
            uniform sampler2D iChannel0;
            uniform sampler2D iChannel1;
            uniform sampler2D iChannel2;
            uniform sampler2D iChannel3;
            uniform vec4      iDate;
            uniform float     iSampleRate;

            vec4 texture(sampler2D s,vec2 uv)
            {
                return texture2D(s,uv);
            }
            "

        readonly property string
        startCode: "
            void main(void)
            {

                mainImage(gl_FragColor, vec2(qt_TexCoord0.x,qt_TexCoord0.y)*vec2(iResolution.x,iResolution.y));
            }"


        //NOTE:shadertoy的texture换成texture2D
        property string pixelShader:
            "
            void mainImage( out vec4 fragColor, in vec2 fragCoord )
            {
                vec2 uv = fragCoord/iResolution.xy;
                fragColor =  texture2D(iChannel0,uv);

            }
            "

        fragmentShader: forwordPixelShaderString + pixelShader + startCode

    }
    ScrollView {
        id: textedit_view
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.left: shader.right
        anchors.rightMargin:  10
        anchors.leftMargin: 10
        anchors.bottomMargin: 5
        width: parent.width

        background: Rectangle{
            border.color: textEditor.activeFocus? "blue": "black"
            border.width: textEditor.activeFocus? 2: 1
        }
        clip: true

        TextEdit{
            //                activeFocusOnPress:true
            padding: 5
            //鼠标选取文本默认为false
            selectByMouse:true;
            anchors.fill: parent
            id:textEditor
            selectionColor: "#4A6DBC" //设置选择框的颜色
            //                background :  Rectangle{
            //                    color: "black"
            //                }
            text: shader.pixelShader
            wrapMode: TextEdit.Wrap
            textFormat: TextEdit.PlainText
            font.family: "Helvetica"
            font.pointSize: 8
            color: "black"
            focus: true

            //键盘选取文本默认为true
            selectByKeyboard: true
            //选中文本的颜色
            selectedTextColor: "white"
            //clip: true
            //默认Text.QtRendering看起来比较模糊
            renderType: Text.NativeRendering

        }
    }

    Row{
        id:image_row
        anchors.bottom:  parent.bottom
        anchors.horizontalCenter: shader.horizontalCenter
        height: 200
        spacing: 10
        Image{
            id:image0

            width: 140
            height: 200
            fillMode: Image.PreserveAspectFit
            source: "png/texture20.jpg"
            visible: true

            Rectangle{
                anchors.fill: parent
                border.width: 2
                border.color: "red"
                color: "transparent"
                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:{
                        this.cursorShape = Qt.PointingHandCursor
                        parent.border.color = "blue"
                    }
                    onExited:{
                        parent.border.color = "red"

                    }
                    onClicked: {
                        channel =0;
                        loader.sourceComponent = itemCompont
                    }
                }
            }


        }
        Image{
            id:image1

            width: 140
            height: 200
            fillMode: Image.PreserveAspectFit
            source: ""
            visible: true
            Rectangle{
                anchors.fill: parent
                border.width: 2
                border.color: "red"
                color: "transparent"
                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:{
                        this.cursorShape = Qt.PointingHandCursor
                        parent.border.color = "blue"
                    }
                    onExited:{
                        parent.border.color = "red"

                    }
                    onClicked: {
                        channel =1;
                        loader.sourceComponent = itemCompont
                    }
                }
            }

        }
        Image{
            id:image2

            width: 140
            height: 200
            fillMode: Image.PreserveAspectFit
            source: ""
            visible: true
            Rectangle{
                anchors.fill: parent
                border.width: 2
                border.color: "red"
                color: "transparent"
                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:{
                        this.cursorShape = Qt.PointingHandCursor
                        parent.border.color = "blue"
                    }
                    onExited:{
                        parent.border.color = "red"

                    }
                    onClicked: {
                        channel =2;
                        loader.sourceComponent = itemCompont
                    }
                }
            }
        }


        Image{
            id:image3

            width: 140
            height: 200
            fillMode: Image.PreserveAspectFit
            source: ""
            visible: true
            Rectangle{
                anchors.fill: parent
                border.width: 2
                border.color: "red"
                color: "transparent"
                MouseArea{
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered:{
                        this.cursorShape = Qt.PointingHandCursor
                        parent.border.color = "blue"
                    }
                    onExited:{
                        parent.border.color = "red"

                    }
                    onClicked: {
                        channel =3;
                        loader.sourceComponent = itemCompont
                    }
                }
            }
        }
    }








    Button{
        id:xuanzhuan
        width: 60
        height: 30
        anchors.left: parent.left
        anchors.top: shader.bottom
        text: "旋转"
        onClicked: {
            shader.rotation = (shader.rotation+180)%360

        }
    }
    Button{
        id:fanzhuan
        width: 60
        height: 30
        anchors.left: xuanzhuan.right
        anchors.top: shader.bottom
        text: "翻转"
        onClicked: {
            //绕y轴旋转
            shader.rotationAngle =  (shader.rotationAngle+180)%360;
        }


    }
    Button{
        id:run
        width: 60
        height: 30
        anchors.left: fanzhuan.right
        anchors.top: shader.bottom
        text: "run"
        onClicked: {
            shader.fragmentShader = shader.forwordPixelShaderString + textEditor.text + shader.startCode

        }
    }
    Button{
        id:example0
        //        width: 60
        height: 30
        anchors.right: shader.right
        anchors.top: shader.bottom
        text: "example0"
        onClicked: {

            var shaderText = "
                            // Maximum number of cells a ripple can cross.
                            #define MAX_RADIUS 2

                            // Set to 1 to hash twice. Slower, but less patterns.
                            #define DOUBLE_HASH 0

                            // Hash functions shamefully stolen from:
                            // https://www.shadertoy.com/view/4djSRW
                            #define HASHSCALE1 .1031
                            #define HASHSCALE3 vec3(.1031, .1030, .0973)

                            float hash12(vec2 p)
                            {
                                vec3 p3  = fract(vec3(p.xyx) * HASHSCALE1);
                                p3 += dot(p3, p3.yzx + 19.19);
                                return fract((p3.x + p3.y) * p3.z);
                            }

                            vec2 hash22(vec2 p)
                            {
                                vec3 p3 = fract(vec3(p.xyx) * HASHSCALE3);
                                p3 += dot(p3, p3.yzx+19.19);
                                return fract((p3.xx+p3.yz)*p3.zy);

                            }

                            void mainImage( out vec4 fragColor, in vec2 fragCoord )
                            {
                                float resolution = 10. * exp2(-3.*iMouse.x/iResolution.x);
                                vec2 uv = fragCoord.xy / iResolution.y * resolution;
                                vec2 p0 = floor(uv);

                                vec2 circles = vec2(0.);
                                for (int j = -MAX_RADIUS; j <= MAX_RADIUS; ++j)
                                {
                                    for (int i = -MAX_RADIUS; i <= MAX_RADIUS; ++i)
                                    {
                                        vec2 pi = p0 + vec2(i, j);
                                        #if DOUBLE_HASH
                                        vec2 hsh = hash22(pi);
                                        #else
                                        vec2 hsh = pi;
                                        #endif
                                        vec2 p = pi + hash22(hsh);

                                        float t = fract(0.3*iTime + hash12(hsh));
                                        vec2 v = p - uv;
                                        float d = length(v) - (float(MAX_RADIUS) + 1.)*t;

                                        float h = 1e-3;
                                        float d1 = d - h;
                                        float d2 = d + h;
                                        float p1 = sin(31.*d1) * smoothstep(-0.6, -0.3, d1) * smoothstep(0., -0.3, d1);
                                        float p2 = sin(31.*d2) * smoothstep(-0.6, -0.3, d2) * smoothstep(0., -0.3, d2);
                                        circles += 0.5 * normalize(v) * ((p2 - p1) / (2. * h) * (1. - t) * (1. - t));
                                    }
                                }
                                circles /= float((MAX_RADIUS*2+1)*(MAX_RADIUS*2+1));

                                float intensity = mix(0.01, 0.15, smoothstep(0.1, 0.6, abs(fract(0.05*iTime + 0.5)*2.-1.)));
                                vec3 n = vec3(circles, sqrt(1. - dot(circles, circles)));
                                vec3 color = texture(iChannel0, uv/resolution - intensity*n.xy).rgb + 5.*pow(clamp(dot(n, normalize(vec3(1., 0.7, 0.5))), 0., 1.), 6.);
                                fragColor = vec4(color, 1.0);
                            }
                            "
            shader.fragmentShader = shader.forwordPixelShaderString + shaderText + shader.startCode

        }
    }


    Loader {
        id: loader
        source: ''
        anchors.fill:parent


        function onDisDeleteThis() {
            loader.sourceComponent = undefined
        }
        function onClickPng(png) {

            switch(channel){
            case 0:
                image0.source =png
                break;
            case 1:
                image1.source =png
                break;
            case 2:
                image2.source =png
                break;
            case 3:
                image3.source =png
                break;

            }

            loader.sourceComponent = undefined

        }
        onLoaded: {
            loader.item.deleteThis.connect(loader.onDisDeleteThis)
            loader.item.clickPng.connect(loader.onClickPng)
        }
    }

    Component {
        id: itemCompont
        Rectangle {
            id: compontRect
            color: "#c0000000"
            implicitWidth: 200
            implicitHeight: 50

            signal deleteThis()
            signal clickPng(var png)
            Grid {
                id: interText
                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 4
                columns:6
                Image{
                    width: 120
                    height: 120
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture0.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }}

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture1.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        } }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture2.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }
                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture3.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        } }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture4.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }
                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture5.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        } }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture6.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }  }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture7.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }}

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture8.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }
                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture9.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }  }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture10.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }
                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture11.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }

                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture12.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture13.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture14.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture15.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture16.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }

                    }
                    Image{
                        width: 120;
                        height: 120;
                        fillMode: Image.PreserveAspectFit
                        source: "png/texture17.jpg"
                        visible: true
                        Rectangle{
                            anchors.fill: parent
                            border.width: 2
                            border.color: "red"
                            color: "transparent"

                        }
                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture18.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture19.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture20.jpg"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor

                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
                Image{
                    width: 120;
                    height: 120;
                    fillMode: Image.PreserveAspectFit
                    source: "png/texture21.png"
                    visible: true
                    Rectangle{
                        anchors.fill: parent
                        border.width: 2
                        border.color: "red"
                        color: "transparent"


                        MouseArea{
                            anchors.fill: parent
                            hoverEnabled: true
                            onEntered:{
                                this.cursorShape = Qt.PointingHandCursor
                                parent.border.color = "blue"
                            }
                            onExited:{
                                parent.border.color = "red"

                            }
                            onClicked: {

                                compontRect.clickPng(parent.parent.source);
                            }
                        }
                    }

                }
            }
            Button {
                anchors.margins: 5
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.right: parent.right
                text: 'close'

                onClicked: {
                    compontRect.deleteThis()
                }
            }
        }

    }
}
