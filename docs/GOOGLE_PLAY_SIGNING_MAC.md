# Vimi · Mac 正式签名与打包

最终包名为 `com.vimistudio.covercrew`。签名证书及其 SHA-256 指纹用于验证上传和安装包。Google Play 管理分发用的应用签名密钥，你保管用于上传 AAB 的密钥。私钥、密码和本地签名配置只保存在你的电脑和可靠备份中。 [Play App Signing](https://support.google.com/googleplay/android-developer/answer/9842756?hl=en)

如果旧账号终止决定涉及同一发布主体，先处理 [填报单中的发布资格事项](GOOGLE_PLAY_FORM_GUIDE.md#送审前待确认)，再送审。

## 1. 进入项目目录，确认 JDK 和签名配置

```bash
cd /Users/chengdupengyuyan/Fun/Vimi
flutter doctor -v

VIMI_JBR="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
"$VIMI_JBR/bin/java" -version
git check-ignore android/key.properties config/app.json
```

最后一行应列出两个本地配置文件。若 Android Studio 安装在其他位置，把 `VIMI_JBR` 改成该安装目录实际的 JDK 路径。 `config/app.json` 已配置 Vimi 的公开政策链接。

## 2. 准备上传密钥

**首次发布且 Play Console 没有为此应用登记过上传密钥时**，运行下面这段。密码等终端提示后再输入。命令会拒绝写入已有的同名密钥文件。

```bash
VIMI_UPLOAD_KEYSTORE="$HOME/.android/keystores/vimi-upload.jks"
(
  umask 077
  mkdir -p "$HOME/.android/keystores"
  if [ -e "$VIMI_UPLOAD_KEYSTORE" ]; then
    printf '%s\n' "已有密钥文件，请确认它是否为此应用的上传密钥。"
    exit 1
  fi
  "$VIMI_JBR/bin/keytool" -genkeypair \
    -keystore "$VIMI_UPLOAD_KEYSTORE" \
    -storetype JKS \
    -alias vimi-upload \
    -keyalg RSA \
    -keysize 2048 \
    -validity 10000 \
    -dname "CN=Vimi Upload"
)
```

如果这个应用已登记上传证书，使用对应的原密钥文件和别名。原上传密钥丢失时，从 Play Console 申请重置上传密钥。密钥创建后把密钥文件与密码安全备份。 [Android 签名](https://developer.android.com/studio/publish/app-signing)

## 3. 填写本机签名配置

```bash
if [ ! -f android/key.properties ]; then
  (umask 077; cp android/key.properties.example android/key.properties)
fi
chmod 600 android/key.properties
nano android/key.properties
```

按下面的格式填真实密码和绝对路径。若使用已有密钥，将别名和路径换成实际值。

```properties
storePassword=密钥库密码
keyPassword=密钥条目密码
keyAlias=vimi-upload
storeFile=/Users/你的Mac用户名/.android/keystores/vimi-upload.jks
```

在 `nano` 里按 **Ctrl+O**、**Enter** 保存，再按 **Ctrl+X** 退出。Gradle 从这个本地文件读取密码。终端命令里无需写密码。

## 4. 生成 AAB

如果最终包名从未上传过 AAB，可用当前的 `1.0.0+1`。如果已上传过测试包，构建时用高于此前上传版本的 `versionCode`，可用 `--build-number` 指定。旧的模拟器预览 APK 编号与 Play Console 计数分开。

```bash
flutter build appbundle --release --dart-define-from-file=config/app.json
```

输出文件为 `build/app/outputs/bundle/release/app-release.aab`。把它上传到 Play Console 的封闭式测试轨道。 [Flutter 安卓发布](https://docs.flutter.dev/deployment/android)

## 5. 上传前核对

```bash
VIMI_AAB="build/app/outputs/bundle/release/app-release.aab"
"$VIMI_JBR/bin/jarsigner" -verify "$VIMI_AAB"
git check-ignore android/key.properties config/app.json
```

如需核对证书，用以下命令在本机比较两处 SHA-256 指纹。两处应一致。Play 分发的 APK 由 Google 的应用签名密钥签名，控制台将分别显示上传证书和应用签名证书。

```bash
"$VIMI_JBR/bin/keytool" -printcert -jarfile "$VIMI_AAB"
"$VIMI_JBR/bin/keytool" -list -v -keystore "$VIMI_UPLOAD_KEYSTORE" -alias vimi-upload
```

正式 AAB 的包名、版本、合并权限、16 KB 对齐及运行兼容性要单独核对。可在 Play 的 App Bundle Explorer 检查版本，也可以用官方 `bundletool` 核对包名和打包配置，并用 16 KB 设备运行最终包。 [16 KB 验证指南](https://developer.android.com/guide/practices/page-sizes)

旧记录的处理以 Google 邮件里的具体处分为准。如果是应用拒审，按列出的原因修正。如果是开发者账号终止，走通知中的申诉途径。换包名或签名不能解除账号限制。 [Google Play 执法流程](https://support.google.com/googleplay/android-developer/answer/9899234?hl=en) · [账号申诉入口](https://support.google.com/googleplay/android-developer/troubleshooter/2993242?hl=en)
