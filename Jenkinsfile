pipeline {
    agent any
    stages {
        stage('Checkout') {
            steps {
                git 'https://github.com/your-org/react-native-app.git'
            }
        }
        stage('Clean node modules') {
            steps {
                sh 'rm -rf node_modules'
                sh 'npm install'
            }
        }
        stage('Install Dependencies') {
            steps {
                sh 'npm install'
            }
        }
        stage('Build Android APK') {
            steps {
                sh 'cd android && ./gradlew assembleRelease'
            }
        }
        stage('Archive APK') {
            steps {
                archiveArtifacts artifacts: 'android/app/build/outputs/apk/release/*.apk', fingerprint: true
            }
        }
        stage('Upload to Nexus') {
            steps {
                sh 'curl -u admin:admin123 --upload-file android/app/build/outputs/apk/release/app-release.apk http://nexus.local/repository/apk-hosted/app-release.apk'
            }
        }
    }
}
