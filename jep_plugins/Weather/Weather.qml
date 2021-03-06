import QtQuick 2.1
import QtQuick.Controls 1.1
import ".."

Rectangle {
    id: root

    JepSettings {
        id: settings
        settingsPath: "Weather.settings"

        property int cityId: 524901
        property bool metric: true
        property string lang: "en"
        property int refreshPeriod: 15 // minutes
    }

    //width: 100
    height: cityName.height+temp.height+icon.height
    color: "gray"

    Column {
        Text {
            id: cityName
            text: "Loading..."

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { parent.font.underline = true; parent.color = "blue"; }
                onExited: { parent.font.underline = false; parent.color = "black"; }
                onClicked: selectCityDlg.show()
            }
        }

        Text {
            id: temp

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: { parent.font.underline = true; parent.color = "blue"; }
                onExited: { parent.font.underline = false; parent.color = "black"; }
                onClicked: {
                    optionsDlg.showModal(settings.metric, settings.lang);
                }
            }
        }

        Rectangle {
            width: parent.width
            height: icon.height
            color: "transparent"

            Image {
                id: icon
                height: 50
            }

            Text {
                id: weather
                anchors.bottom: icon.bottom
                font.bold: true
                wrapMode: Text.Wrap
                width: root.width
                opacity: 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 500
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                onEntered: weather.opacity = 1
                onExited: weather.opacity = 0
            }
        }
    }

    SelectCityDlg {
        id: selectCityDlg
        onAccepted: {
            settings.cityId = cityId;
            startLoadingWeather();
        }
    }

    OptionsDlg {
        id: optionsDlg
        onAccepted: {
            settings.metric = metric;
            settings.lang = lang;
            startLoadingWeather();
        }
    }

    Timer {
        id: refresh
        interval: 1000*60*settings.refreshPeriod
        repeat: true
        running: true

        onTriggered: startLoadingWeather();
    }

    Component.onCompleted: {
        settings.load();
        startLoadingWeather();
    }

    function startLoadingWeather() {
        cityName.text = "Loading...";
        temp.text = "";
        icon.source = "";

        var doc = new XMLHttpRequest();
        doc.onreadystatechange = function() {
            if (doc.readyState === XMLHttpRequest.DONE) {
                if (doc.status === 200)
                    onWeatherLoaded(doc);
                else
                    cityName.text = doc.statusText;
            }
        }

        var units = settings.metric ? "metric" : "imperial";
        var url = "http://api.openweathermap.org/data/2.5/weather?id=%1&lang=%2&units=%3&APPID=79e8f327892ff196b77b400988291a2a".arg(settings.cityId).arg(settings.lang).arg(units);
        doc.open("get", url);
        doc.setRequestHeader("Content-Encoding", "UTF-8");
        doc.send();
    }

    function onWeatherLoaded(doc) {
        var responseText = doc.responseText;
        if (responseText.length === 0) {
            cityName.text = "Loading Failed";
            return;
        }

        var rObj = JSON.parse(responseText);
        if (rObj.cod !== 200) {
            cityName.text = "%1-'%2'".arg(rObj.cod).arg(rObj.message);
            return;
        }

        cityName.text = "%1 (%2)".arg(rObj.name).arg(rObj.sys.country);
        var tempSign = settings.metric ? "C" : "F";
        temp.text = "%1 %2".arg(rObj.main.temp).arg(tempSign);
        icon.source = "http://openweathermap.org/img/w/%1.png".arg(rObj.weather[0].icon);
        weather.text = rObj.weather[0].description;
    }
}
