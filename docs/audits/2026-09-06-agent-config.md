# Claude Code / Codex 設定棚卸し — 2026-09-06

対象は takenv の共通指示・スキル・起動経路、および `~/github/reflllc/bak.pj` のエージェント設定と関連CI。ブランチを作らず作業ツリーへ反映した。既存の docker-compose 変更、proxy接続、モデル設定、Orca連携hooksは保持した。

## 主な問題と処置

| 問題 | 処置 |
|---|---|
| 「責任者」指示は Claude の shell関数経由だけ。Codex の共通 AGENTS は不存在 | `.agents/AGENTS.md` を正本にして両ツールから読み込む |
| 常時委譲、同期のみ、固定人数・モデル、責任者の即終了を要求 | 単発はsubagent、継続対話はHerdr、短い作業は直接実行。継続対話の間は担当を維持 |
| 共通skillを `.agents` と `.codex` へ二重に登録 | Codexのnative discoveryへ統一、29個の旧リンクと同期targetを削除 |
| 共通コマンドが `develop`、bak.pj は `pre-develop` | 実際のPR base・repo規約を使用。bak.pjは指定がなければpre-develop |
| Codex promptがClaude専用Agent Teams・opus人数を要求 | `do-issue` を短い共通skillに置換 |
| `cw` に廃止済み `--enable-auto-mode` | `--permission-mode auto` に更新 |
| bak.pjのルール・スキルがClaudeからしか発見できない | repo AGENTSに領域別ルール索引を追加、8スキルを`.agents/skills`へ移動 |
| CIの短い追加指示が `--system-prompt` で標準指示を全置換 | 関連6 workflow、12箇所を `--append-system-prompt` へ変更 |
| 日次自動リファクタCIが4個の不存在skillを呼び出す | `antipattern-scan.yml` を廃止。既存PRレビュー・脆弱性修正CIは維持 |
| UATの合否と無関係なファイルmtimeでPR作成をブロック | `uat-checklist-gate.sh` とそのhookを削除 |
| UATをMCP限定・未準備なら停止、生成開始だけで一律pass | スクリプトを許容、不足準備を実施、項目の期待結果まで検証 |
| UAT差分800行、技術ノート差分500行で打ち切り | 全差分を分割して読む。未読部分をファイル名から推定しない |
| BRIEF正本がローカルとcanvasの両方に存在 | 実装と保守する画面要件はBRIEF、共有概要はcanvas |
| 参照・質問だけの依頼でもSlack投稿を要求 | 読み取りと外部更新を分離、既存の承認は取り直さない |
| 未コミット差分がある状態で `git diff --exit-code` を整形判定に使用 | 変更ファイルの整形前後を比較する運用へ |
| PostToolUseで毎回npx整形、textlintで作業停止 | 自動整形hookを削除、textlintは助言に変更 |
| テストDB作成のため既存Docker volume削除を案内 | 不足するテストDB・拡張だけ作成する説明へ |
| 既存override変更禁止で脆弱性パッチが阻害される | 今回の脆弱性解消に必要なoverride更新を許可 |
| 業務ノートを生成前にgrepし、先に生成すると既存拒否 | 出力先確認→生成→NG検査の順序に統一 |

共通SKILL.mdの入口は29件・4,323行から33件・2,714行へ。約37%減。詳細を参照ファイルへ分離した分を含むため、すべてが知識の削除ではない。モデルの実タスク性能向上を数値で実証した値でもない。

## 共通スキルの棚卸し

| スキル | 判断 |
|---|---|
| animate | 固定値・入力方式による禁止を、利用頻度・応答性・実測での判断へ |
| animation-vocabulary | 維持。効果名を探す用途が独立している |
| apple-design | 維持。gesture・typography・materialの固有観点がある |
| ask-sonner | 一律Toaster1個と複数Toaster手順の矛盾を解消 |
| auditcodex | read-only sandbox、既定モデル、衝突しない一時領域、修正依頼済みなら続行 |
| browser | 全環境bootstrapを外し、不足依存だけ準備。networkidle万能視を修正 |
| codex-imagegen | 維持。CLI経由の画像生成という環境固有の手段 |
| do-issue | 旧Codex promptから共通化。Claude固有の計画・多重委譲を削除 |
| docs-compact | 旧docs:compact。本文を短縮し、数値・引用・コードの保持を統一 |
| emil-design-eng | 定型応答待ち・文体強制を削除。motion/components詳細を参照へ分離 |
| empirical-prompt-tuning | 独立評価の核を保持。固定反復数・時間変動による収束判定を削除 |
| find-animation-opportunities | 読取提案の用途を維持。transform/opacity限定等を整合 |
| find-skills | 維持。外部スキル探索は別用途 |
| fix-actions-check | 旧Claude commandから共通化。OSV一律無視・実在人物役の強制を削除 |
| fix-conflict | 旧Claude commandから共通化。base決め打ちを削除 |
| frontend-design | ローカルの正本を維持。重複するClaudeプラグインを無効化 |
| gogcli | 操作例をサービス別referencesへ分離。現在のCLI helpを優先 |
| grill-me | 短い別名として維持。Claude専用Skill tool呼出を相対参照へ |
| grilling | 全仮想分岐が尽きるまで質問する条件を削除。重要判断で区切る |
| herdr | 「責任者」依頼も発火条件に追加。1役割1tab、非同期投入と明示回収を両立 |
| image2pptx | 旧slide:image2pptx。親の実装禁止・委譲不能時停止を削除。全モードで同一成果物書込みを直列化 |
| improve-animations | 修正依頼の拒否とexecuteモードの矛盾を解消。計画だけ/実装までを依頼で区別 |
| issue-triage | 特定プロダクトのコア機能・古さだけのclose・再承認・自動メンションを削除 |
| japanese-tech-writing | 維持。日本語原稿の整形・論証の固有規約 |
| llm-design-check | 永続化境界を維持。fuzzy一本・10%許容・追加call・retry1回の全用途固定を撤去 |
| pick-ui-library | 維持。明示呼出のみの選定資料 |
| prompt-digest | 旧Claude commandから共通化。過去7日分の再集計による二重加算を除去 |
| prototype | 比較試作の用途を維持。アニメーションの一律禁止を整合 |
| react-doctor | 毎回の全体診断を誘うtriggerを狭め、スコアを完了ゲートにしない |
| review-animations | 反証は実際の応答性・連続性・描画コストに基づく。好みだけの自動failを撤去 |
| skill-authoring | native `.agents/skills`、標準名、CI導入経路を正本として短縮 |
| slide-create | 旧slide:create。auto-size指定の矛盾と行高計算の誤りを修正 |
| zero-base-check | 維持。対象の変更層を比較し、無関係な全面再設計を避ける用途 |

欠けていたnameを補い、ディレクトリ名と揃えた。共通skillの`context: fork`固定は削除し、両ツールで通常の呼出から使えるようにした。公式同梱の`.system`スキルは配布物なので編集していない。

## その他の設定

- Claude Agent Teamsの実験フラグと表示設定を削除。Herdrとsubagentの運用に統一した。
- Claudeの旧`includeCoAuthoredBy`を`attribution`へ整理。
- Gmail送信の恒久denyをaskへ変更し、明示承認された送信ができる形にした。通常の閲覧から送信は追加しない。
- 意味のないPlaywright deny項目、空の旧plugin設定、存在しないagmsgのCodex shimを削除。
- `member` をMakefileの配布対象へ追加。
- Codexの`project_doc_fallback_filenames`にCLAUDE.mdを指定し、AGENTS未導入の既存repoでも入口を読めるようにした。
- bak.pjの共有settingsから個人モデル・Agent Teams・共通権限の複製、無効なトップレベルaskを除去。
- 自動蓄積したlocal許可を整理。bak.pjは148件→15件、takenvは37件→4件。過去のPID、作業用ファイル、旧worktree、本番接続の一回限りの許可等を取り除いた。local設定はgit管理外。
- ログ記録・statusline・既存Orca hooksは維持。実行時データ・OAuth資格情報・全セッション履歴は棚卸し対象へ読み込んでいない。

## 検証

- Codex CLI 0.153.4のapp-server `skills/list`を実行。takenvで共通33件、bak.pjで共通33件＋repo8件、探索エラー0を確認。
- `make check-agent-config` と `--repo ~/github/reflllc/bak.pj` がpass。symlink、name、参照、JSON/TOML構文を検査。
- スキル41件とpaths規約7件をYAMLパーサでも検査。
- 検査スクリプトは正常例、参照切れ、不正nameのfixtureで、期待した成功/失敗を確認。
- 変更した6 workflowをactionlintで検査。指示文の変更が中心のためShellCheck/Pyflakesは無効にし、Actions構文とexpressionを検査。
- shell構文、両repoの`git diff --check`を確認。
- 独立した読み手で共通スキルとbak.pj設定を構造審査。さらに新規の読み手2回、計8シナリオで模擬判断を実施。責任者委譲、局所修正、MCPなしUAT、参照のみのSlack、修正までの監査、本番DBへの逸脱を確認。初回で出た停止文言を修正し、再確認で期待した行動を確認した。

模擬判断は実ツールを伴う作業成功率の測定ではない。Claude Code 2.1.236で共通指示の回答確認を試したが、応答が返らず中止したため、ClaudeのLLM応答による読込検証は未完了。importとsymlinkの実体は確認済み。Herdrで実装・レビュー担当を動かす長期運用と、GitHub Actionsのクラウド実行は未実施。変更は未コミットで、外部へpush・workflow実行・Slack投稿はしていない。

## 公式仕様との対応

Codexのglobal AGENTSとfallback、`.agents/skills`の探索・symlink対応に合わせた。[AGENTS.md](https://developers.openai.com/codex/guides/agents-md)、[Skills](https://developers.openai.com/codex/skills)

ClaudeはCLAUDE.mdからAGENTS.mdをimportでき、必要な情報をskillsへ分ける運用が公式に案内されている。[Memory](https://code.claude.com/docs/en/memory#agentsmd)、[Best practices](https://code.claude.com/docs/en/best-practices)

nameとディレクトリの一致、英数字・ハイフンの形式、詳細資料の段階的な読込はAgent Skillsの仕様に合わせた。[Specification](https://agentskills.io/specification)

CIの追加指示は標準プロンプトを残すappendフラグへ変更した。[CLI reference](https://code.claude.com/docs/en/cli-reference#system-prompt-flags)

## 追補: チームメンバーが bak.pj だけを clone する場合

takenv は個人設定であり、チームの配布元として必須にしない。bak.pj の8スキルはリポジトリ内の実ファイルで、Claude 用リンクも同一リポジトリ内に解決する。

残っていた個人用 `fix-conflict` / `llm-design-check` への依存を、AGENTS・領域規約・逆流 PR 本文に必要な手順を直接書く形へ変更した。GitHub アカウント名と Herdr worktree パスの決め打ちを除去し、委譲機能のない環境でも実装・UAT を進められるようにした。bak.pj の README から `docs/agent-setup.md` を案内する。takenv の skill-authoring にもチームの必須手順はチーム repo に置く規約を追加した。

bak.pj のエージェント設定を `/tmp/agent-config-team-portability/standalone` にコピーして、リンクがコピー先の内部に収まること、8スキルの形式と参照、CI が使うスキルの同梱を確認した。Codex app-server の skills/list でもコピー先の8スキルを認識し、errors は0。個人設定の読み込み自体を無効化した試験ではなく、リポジトリ内の配置・参照・探索の検証であり、アプリ環境の構築やクラウド CI は実行していない。
