# Vimi · Google Play 填报单

核对日期为 2026 年 11 月 23 日。适用于 Vimi 的免费安卓首发版，包名为 `com.vimistudio.covercrew`。先完成内部测试，再补齐商店资料和应用内容声明、做封闭测试，最后申请正式发布权限。表单选项和补充问题以实际发行地区、版本和控制台提示为准。

## 送审前待确认

- **发布资格**。如旧账号终止决定涉及同一发布主体，先按 Google 原通知申诉或确认发布资格。 [Google Play 违规处置](https://support.google.com/googleplay/android-developer/answer/9899234?hl=zh-Hans)
- **儿童安全负责人姓名**。暂空，提交儿童安全声明前补填有能力处理相关事件的真实联系人姓名。邮箱已确认。
- **封闭测试人员**。当前尚未凑齐 12 位测试者。积累实际反馈并达到连续加入天数后，才可申请正式发布权限。

## 0. 先做内部测试

1. 在 Play Console 首页处理账号验证提示。如果显示设备验证任务，账号所有者在未 Root、运行 Android 10 或以上的安卓实体手机上，用 Play Console 手机应用完成验证。 [设备验证](https://support.google.com/googleplay/android-developer/answer/14316361?hl=zh-Hans)
2. 在 **所有应用 → 创建应用** 填写应用名 `Vimi Dance Covers`、默认语言 `English (United States)`，选择 **应用**、**免费**。如果页面询问包名，填 `com.vimistudio.covercrew`。联系邮箱填 `funchan7777777@gmail.com`。核对并处理创建页要求的声明。 [创建应用](https://support.google.com/googleplay/android-developer/answer/9859152?hl=zh-Hans)
3. 在 Mac 上按 [签名打包步骤](GOOGLE_PLAY_SIGNING_MAC.md) 生成上传签名的 `build/app/outputs/bundle/release/app-release.aab`。如果本包名还没上传过，首包可用 `1.0.0`、版本代码 `1`。首次上传后，这个应用的包名固定。
4. 打开 **测试和发布 → 测试 → 内部测试 → 测试人员**。创建邮箱名单，先加你自己手机上 Play 商店正在登录的 Google 账号，有其他可信测试者也可加。勾选名单并保存。反馈邮箱填 `funchan7777777@gmail.com`。Google 账号用于加入 Play 测试，Vimi 登录使用应用内账号。
5. 切到 **版本 → 创建新版本**，按提示设置 Play App Signing，上传 AAB，核对包名和版本。检查预览后，在**内部测试轨道**发布。如果 **发布概览** 显示有变更等待提交审核，按控制台提示提交，等轨道显示可用。首次发布可能需要审核，具体看控制台状态。 [内部测试设置](https://support.google.com/googleplay/android-developer/answer/9845334?hl=zh-Hans) · [审核与发布状态](https://support.google.com/googleplay/android-developer/answer/9859654?hl=zh-Hans)
6. 在 **测试人员** 页复制加入链接。在安卓手机上用刚才加入名单的 Google 账号打开链接，加入测试，然后从 Google Play 安装 Vimi。当前阶段可以从一位测试者开始。

安装后优先验证注册、登录与密码找回，短视频播放、发帖、评论、举报、拉黑、账号删除和政策链接。双人测试时，用两个 Vimi 账号互关，验证消息、语音和视频通话。记录设备型号、Android 版本、应用版本和复现步骤。有修复时，提高 `versionCode` 后把新 AAB 发到内部测试轨道复测。

内部测试的参与人数和天数不计入后续封测要求。内部测试通过后，在 Console 的 **应用内容（App content）** 按下面的表格填报，补齐商店文案和图，再发布封测。儿童安全负责人姓名在此时补填。 [新个人账号测试要求](https://support.google.com/googleplay/android-developer/answer/14151465?hl=zh-Hans)

## 1. Privacy policy

填入 `https://vimi-dance.pages.dev/privacy`。官网地址为 `https://vimi-dance.pages.dev/`。应用内注册页和设置页提供政策入口。使用条款、社区规则、儿童安全和删除页分别为 `/terms`、`/community`、`/child-safety` 和 `/deletion`。 [官方填报说明](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)

## 2. App access

| 字段 | 填写内容 |
| --- | --- |
| 访问限制 | 选需要凭据才能访问全部或部分功能的选项 |
| 说明名称 | `Vimi member access` |
| Username / email | 从本机的 `config/play-review-access.json` 取普通审核账号邮箱 |
| Password | 从同一文件取密码，填入 Console 的密码字段 |
| Additional instructions | 登录已复核后，粘贴下方英文 |

```text
Open Vimi and tap Sign in below Join the crew. Enter the supplied email and password. No email code is required. Floor shows covers and dancer profiles. Studio has the journal and practice plans. To test messaging and calls, use two member accounts and follow each other. Report posts or comments from their menus. Find account deletion under Me > Settings.
```

用正式包复核一次普通审核账号。双人聊天和通话另准备第二个普通账号，将其凭据和操作说明填入 Console。审核员后台使用独立权限，审核期间让内容审核人员负责处理测试举报。 [Google 审核登录要求](https://support.google.com/googleplay/android-developer/answer/15748846?hl=en)

## 3. Ads

当前发布版本选 **No**。Vimi 使用自己的 Studio 参考素材和功能入口。正式包要与该声明一致。 [广告声明](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)

## 4. Target audience and content

选择 **18 and over** 作为目标年龄。商店类别选 **Social**。注册要求填写出生日期及同意使用条款和社区规则。商店文案及图片面向成年舞者。 [目标受众说明](https://support.google.com/googleplay/android-developer/answer/9859455?hl=en)

## 5. Content rating

填可接收评级通知的邮箱，再按实际回答 IARC 问卷。Vimi 支持用户上传舞蹈图片和视频、发布评论、关注、私聊以及语音和视频通话。涉及 **User-generated content**、用户交流和内容访问的问题按这些功能作答。主题涉及的内容按最终发布素材逐题核对。评级由问卷生成。 [内容分级说明](https://support.google.com/googleplay/android-developer/answer/9859653?hl=en)

## 6. Child safety standards

| 字段 | 填写内容 |
| --- | --- |
| Published standards URL | `https://vimi-dance.pages.dev/child-safety` |
| Designated point of contact | 待补。提交前填写能处理儿童安全事件的真实联系人姓名 |
| Contact email | `funchan7777777@gmail.com` |
| In-app feedback / report | 应用内可举报用户、帖子、评论和消息。举报理由含儿童安全和疑似未成年。用正式包验证举报进入审核端后再勾选 |
| Handling CSAM / legal compliance | 由实际负责人核对内容移除、账号处理及依法向有关机构报告的流程后签署声明 |

社交应用的这项声明适用于成年受众。操作人可参考 [Vimi 儿童安全运营流程](CHILD_SAFETY_OPERATIONS.md)。 [Google 儿童安全标准](https://support.google.com/googleplay/android-developer/answer/14747720?hl=en)

## 7. Data safety

### 总开关

| 字段 | 建议填写及检查依据 |
| --- | --- |
| Does your app collect or share user data? | **Yes**。注册、云端资料和社交数据会传送到 Supabase |
| Is all collected user data encrypted in transit? | 当前应用用 HTTPS、安全 Realtime 和 WebRTC。正式包和实际接入的供应商均使用加密传输时，选 **Yes** |
| Account creation methods | 选用户名及密码对应的选项。Vimi 用邮箱作为用户名并使用密码登录 |
| Account deletion URL | `https://vimi-dance.pages.dev/deletion`。应用内路径是 **Me → Settings → Delete account** |
| Request deletion of some or all data | Vimi 支持删除账户和关联数据。删除页还提供通过邮件申请删除特定数据的入口。由支持人员核实能兑现该流程后作答 |

### Data types

勾选每类实际发送到服务器或供应商的数据。只有满足 Google 对供应商处理、用户主动分享等例外条件才可以使用例外。以下列出需要填报和需要按实际日志确认的项目。

| Console 数据类型 | Vimi 的情况 | 用途与是否必需 |
| --- | --- | --- |
| Personal info → Name | 注册显示名和公开资料 | 账号管理、功能。注册必需 |
| Personal info → Email address | 登录邮箱及找回密码 | 账号管理、安全。注册必需 |
| Personal info → User IDs | Supabase 用户 ID、内容和会话关联 | 账号管理、功能、安全。注册必需 |
| Personal info → Other info | 出生日期用于成年准入 | 账号管理、安全及合规。注册必需 |
| Photos and videos → Photos / Videos | 用户保存头像或提交帖子时上传 | 应用功能。可选 |
| Messages → Other in-app messages | 已发送的私聊消息和参与者 | 应用功能、内容安全。可选 |
| Contacts → Contacts | 对照 Google 对站内社交关系的定义，计入关注和好友关系这些账号关联 | 应用功能。可选 |
| App activity → In-app search history | 舞者搜索请求会到服务器，历史日志可包含查询参数 | 应用功能、安全。可选 |
| App activity → App interactions | 关注、点赞、收藏、拉黑等服务器记录 | 应用功能、安全。可选 |
| App activity → Other user-generated content | 简介、动态文案、评论、举报说明 | 应用功能、内容安全。可选 |
| Location → Approximate location | 服务器历史日志记录过由 IP 推断的城市和国家 | 基础设施、安全。核对最终服务日志和使用范围 |
| App info and performance / Device or other IDs | 核查服务商实际记录的技术诊断和可识别会话、设备或浏览器的标识符，分别归入匹配类型 | 依据生产设置确认具体类型、用途和规范中适用的例外 |
| Voice / video calls | 通话连接使用 WebRTC。麦克风音频、视频帧、信令及网络元数据分别核对。信令含参与人和连接信息，按实际删除计划处理 | 通话可选。实时音视频和已保存的信令分别按 Google 的加密、实时处理和共享定义填写 |

本地练习时长、笔记和未发送草稿留在设备上。健康功能声明与 Data safety 分开填写。表格中的“功能、安全、账号管理”请勾选对应的实际用途。表单中的 **Required / Optional** 取决于用户能否选择提供该数据。服务日志和用户主动发帖分别判断。 [Google 数据类型和例外](https://support.google.com/googleplay/android-developer/answer/10787469?hl=en) · [Vimi 数据处理核对表](GOOGLE_PLAY_DATA_SAFETY.md) · [删除要求](https://support.google.com/googleplay/android-developer/answer/13327111?hl=en)

## 8. 其他声明

| Console 项目 | Vimi 的填写方向 |
| --- | --- |
| Financial features | 选不提供金融功能。当前版本免费，已移除钱包和内购 |
| Health apps | Vimi 手动记录舞蹈练习分钟数并设周目标。按 Google 对活动记录的定义，建议选 **Activity and Fitness**。内容限舞蹈练习日志，按实际功能选择 |
| Advertising ID | 选择与最终 AAB 一致的答案。当前代码未使用广告 ID，核对最终合并清单后选 **No** |
| Government apps / News / Dating | 如果 Console 显示这些声明，当前 Vimi 是舞蹈社交，按实际选不属于该类别或不具备相应功能 |
| 发行地区相关声明 | 按实际发行市场以及实际运营主体填写。以 Console 在当前账号显示的任务为准 |

[金融功能声明](https://support.google.com/googleplay/android-developer/answer/13849271?hl=en) · [健康应用声明](https://support.google.com/googleplay/android-developer/answer/14738291?hl=en)

最后打开 **App content → Needs attention**，核对尚未完成的字段。商店文案和版本说明见 [英文商店素材](GOOGLE_PLAY_LISTING.md)。

## 9. 封测与正式发布

1. **测试和发布 → 测试 → 封闭式测试 → 管理轨道 → 测试人员**。添加参与者的 Google 账号邮箱，并配置反馈邮箱。
2. 在该轨道创建版本，从制品库选用通过内部测试的 AAB。代码有改动时，上传版本代码更高且已复测的签名 AAB。若 **发布概览** 显示有待提交更改，点 **送审**。
3. 封测版本可用后复制加入链接，发给名单里的真实测试者。让他们用名单中的 Google 账号主动加入，通过 Google Play 安装并实际使用。参加过内部测试的人先通过原链接退出内部测试，再通过封测链接加入。
4. 至少 12 位测试者保持连续加入 14 天。申请时也要保持达标。把测试期间真实发现的问题、修复内容和复测结果留作答卷材料。
5. 在应用 **信息中心 → 申请正式发布权限**，填写 Google 问卷。

| 问卷主题 | 到时填写的实际材料 |
| --- | --- |
| 招募和使用 | 实际邀请途径、加入测试的人数、他们试过的功能 |
| 反馈 | 反馈渠道、真实收到的问题和建议 |
| 产品用途 | 面向 18 岁以上的舞蹈爱好者，分享舞蹈翻跳、找舞友和记录练习 |
| 正式版准备 | 根据反馈修过的具体问题、复测的设备或操作结果 |

获批后进入 **正式版（Production）→ 国家/地区**，逐项选择控制台支持的首发市场，排除中国大陆、香港、澳门和台湾。如果显示 **世界其他地区**，先核实覆盖范围再选择。封测轨道的地区跟随生产轨道时，确认受邀测试者所在的 Play 地区可参与。地区按用户的 Play 账号地区判定。 [发行地区设置](https://support.google.com/googleplay/android-developer/answer/7550024?hl=zh-Hans)

控制台发放正式发布权限后，可创建正式版或提升已验证的测试版本，核对商店资料，并在 **发布概览** 送审。正式上线以 Console 的审核和发布状态为准。 [封闭测试设置](https://support.google.com/googleplay/android-developer/answer/9845334?hl=zh-Hans) · [个人账号正式发布权限](https://support.google.com/googleplay/android-developer/answer/14151465?hl=zh-Hans) · [正式版本提交](https://support.google.com/googleplay/android-developer/answer/9859348?hl=zh-Hans)
