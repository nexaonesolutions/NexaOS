import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: container
    width: 1920
    height: 1080
    color: "#030814"

    // Fundo Gradiente Radial Simulado
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: "#06132a" }
            GradientStop { position: 1.0; color: "#020610" }
        }
    }

    // Card de Login Centralizado (Frosted Glass Look)
    Rectangle {
        id: loginCard
        width: 380
        height: 480
        anchors.centerIn: parent
        color: "#161b26"
        opacity: 0.95
        radius: 24
        border.color: "#ffffff"
        border.width: 1

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 40
            spacing: 25

            // Avatar do Usuário
            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                width: 90
                height: 90
                radius: 45
                color: "#0088ff"
                border.color: "#00ffcc"
                border.width: 2

                Text {
                    anchors.centerIn: parent
                    text: "N"
                    color: "#ffffff"
                    font.pixelSize: 36
                    font.bold: true
                }
            }

            // Mensagem de Boas-vindas
            Text {
                Layout.alignment: Qt.AlignHCenter
                text: "Bem-vindo ao Nexa OS"
                color: "#ffffff"
                font.pixelSize: 20
                font.bold: true
            }

            // Input de Usuário
            TextField {
                id: txtUser
                Layout.fillWidth: true
                placeholderText: "Usuário"
                text: "arch"
                color: "#ffffff"
                font.pixelSize: 14
                background: Rectangle {
                    color: "#0a0d14"
                    radius: 10
                    border.color: txtUser.focus ? "#0088ff" : "#2d3345"
                    border.width: 1
                }
            }

            // Input de Senha
            TextField {
                id: txtPassword
                Layout.fillWidth: true
                placeholderText: "Senha"
                echoMode: TextInput.Password
                focus: true
                color: "#ffffff"
                font.pixelSize: 14
                background: Rectangle {
                    color: "#0a0d14"
                    radius: 10
                    border.color: txtPassword.focus ? "#0088ff" : "#2d3345"
                    border.width: 1
                }
            }

            // Botão Entrar
            Button {
                id: btnLogin
                Layout.fillWidth: true
                height: 45
                contentItem: Text {
                    text: "Entrar"
                    color: "#ffffff"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.bold: true
                    font.pixelSize: 15
                }
                background: Rectangle {
                    color: btnLogin.down ? "#0066cc" : "#0088ff"
                    radius: 10
                }
                onClicked: {
                    sddm.login(txtUser.text, txtPassword.text, sessionIndex);
                }
            }
        }
    }
}
