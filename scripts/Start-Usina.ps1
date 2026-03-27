# =============================================================================
# Start-Usina.ps1 — Sessão de trabalho da Natural Tecnologia
# Repositório: CarlosSalesNaturalTec/nt-usina
#
# Uso:
#   .\scripts\Start-Usina.ps1
#   .\scripts\Start-Usina.ps1 -LogPath "caminho\para\app.log"
#
# Requer: Windows Terminal (wt.exe) instalado
#   winget install Microsoft.WindowsTerminal
#
# Layout:
#   ┌─────────────────────────┬──────────────────────┐
#   │  PAINEL 1               │  PAINEL 2            │
#   │  Claude Code CLI        │  Backlog Monitor     │
#   │  (entrada de comandos)  │  watch indice.json   │
#   ├─────────────────────────┼──────────────────────┤
#   │  PAINEL 3               │  PAINEL 4            │
#   │  Git log                │  Log da aplicação    │
#   └─────────────────────────┴──────────────────────┘
# =============================================================================

param(
    [string]$LogPath = ""
)

# -----------------------------------------------------------------------------
# Diretório raiz do projeto
# -----------------------------------------------------------------------------
$ProjectDir = Split-Path -Parent $PSScriptRoot

# -----------------------------------------------------------------------------
# Verifica se o Windows Terminal está disponível
# -----------------------------------------------------------------------------
$wtPath = Get-Command "wt.exe" -ErrorAction SilentlyContinue
if (-not $wtPath) {
    Write-Host ""
    Write-Host "ERRO: Windows Terminal (wt.exe) não encontrado." -ForegroundColor Red
    Write-Host "Instale com: winget install Microsoft.WindowsTerminal" -ForegroundColor Yellow
    Write-Host ""
    exit 1
}

# -----------------------------------------------------------------------------
# Detecta arquivo de log da aplicação
# Prioridade: Laravel > Python > pipeline.log genérico
# -----------------------------------------------------------------------------
function Get-AppLog {
    param([string]$CustomPath, [string]$Root)

    if ($CustomPath -and (Test-Path $CustomPath)) {
        return $CustomPath
    }

    $candidates = @(
        "$Root\storage\logs\laravel.log",
        "$Root\logs\app.log",
        "$Root\app.log",
        "$Root\docs\pipeline.log"
    )

    foreach ($f in $candidates) {
        if (Test-Path $f) { return $f }
    }

    # Nenhum encontrado — usa pipeline.log (criado pelo Orquestrador)
    return "$Root\docs\pipeline.log"
}

$AppLog = Get-AppLog -CustomPath $LogPath -Root $ProjectDir

# -----------------------------------------------------------------------------
# Garante que arquivos monitorados existem
# -----------------------------------------------------------------------------
$BacklogPath = "$ProjectDir\backlog\indice.json"
$PipelineLog = "$ProjectDir\docs\pipeline.log"

if (-not (Test-Path "$ProjectDir\backlog")) {
    New-Item -ItemType Directory -Path "$ProjectDir\backlog" | Out-Null
}
if (-not (Test-Path $BacklogPath)) {
    '{"status":"aguardando_inicializacao","features":[]}' | Set-Content $BacklogPath -Encoding UTF8
}
if (-not (Test-Path "$ProjectDir\docs")) {
    New-Item -ItemType Directory -Path "$ProjectDir\docs" | Out-Null
}
if (-not (Test-Path $PipelineLog)) {
    New-Item -ItemType File -Path $PipelineLog | Out-Null
}

# -----------------------------------------------------------------------------
# Comandos de cada painel (inline PowerShell via -NoExit -Command)
# -----------------------------------------------------------------------------

# PAINEL 1 — Claude Code CLI
# Exibe banner e aguarda o usuário iniciar o Claude Code manualmente
$Cmd1 = @"
chcp 65001 | Out-Null
Clear-Host
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host '   Natural Tecnologia - nt-usina          ' -ForegroundColor Cyan
Write-Host '   Fabrica de Software IA                 ' -ForegroundColor Cyan
Write-Host '==========================================' -ForegroundColor Cyan
Write-Host ''
Write-Host 'Projeto: $ProjectDir' -ForegroundColor Gray
Write-Host ''
Write-Host 'Para iniciar o Claude Code:' -ForegroundColor Yellow
Write-Host '  claude' -ForegroundColor White
Write-Host ''
Write-Host 'Para iniciar o pipeline completo (dentro do Claude Code):' -ForegroundColor Yellow
Write-Host '  /fabricar-software' -ForegroundColor White
Write-Host ''
Set-Location '$ProjectDir'
"@

# PAINEL 2 — Pipeline Monitor (backlog + feature atual, atualiza a cada 2s)
$Cmd2 = @"
chcp 65001 | Out-Null
Set-Location '$ProjectDir'
while (`$true) {
    Clear-Host
    Write-Host '[ PIPELINE MONITOR — nt-usina ]' -ForegroundColor Cyan
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Gray
    Write-Host '-------------------------------------------'
    if (Test-Path '$BacklogPath') {
        try {
            `$json = Get-Content '$BacklogPath' -Raw -Encoding UTF8 | ConvertFrom-Json

            # Status geral
            Write-Host ('Pipeline : ' + `$json.status) -ForegroundColor Yellow
            Write-Host ('Fase     : ' + `$json.pipeline_fase_atual) -ForegroundColor Gray
            Write-Host ('Modo     : ' + `$json.operacao_modo) -ForegroundColor Gray
            Write-Host ''

            # Feature em execução no momento
            Write-Host '--- Em execução ---' -ForegroundColor Cyan
            if (`$json.feature_atual) {
                `$fa = `$json.features | Where-Object { `$_.id -eq `$json.feature_atual }
                if (`$fa) {
                    Write-Host ('  [' + `$fa.id + '] ' + `$fa.nome) -ForegroundColor Cyan
                    Write-Host ('  Status: ' + `$fa.status) -ForegroundColor Yellow
                } else {
                    Write-Host ('  ' + `$json.feature_atual) -ForegroundColor Cyan
                }
            } else {
                Write-Host '  Nenhuma feature em execução.' -ForegroundColor DarkGray
            }
            Write-Host ''

            # Resumo por status
            Write-Host '--- Resumo ---' -ForegroundColor Cyan
            `$grupos = `$json.features | Group-Object status
            foreach (`$g in `$grupos) {
                `$cor = switch (`$g.Name) {
                    'concluida'                { 'Green' }
                    'em_desenvolvimento'       { 'Cyan' }
                    'desenvolvimento_concluido'{ 'Blue' }
                    'em_testes'                { 'Yellow' }
                    'bloqueada'                { 'Red' }
                    'em_recuperacao'           { 'Magenta' }
                    default                    { 'DarkGray' }
                }
                Write-Host ('  ' + `$g.Name.PadRight(28) + `$g.Count) -ForegroundColor `$cor
            }
            Write-Host ''

            # Lista completa de features
            Write-Host '--- Features ---' -ForegroundColor Cyan
            foreach (`$f in `$json.features) {
                `$cor = switch (`$f.status) {
                    'concluida'                { 'Green' }
                    'em_desenvolvimento'       { 'Cyan' }
                    'desenvolvimento_concluido'{ 'Blue' }
                    'em_testes'                { 'Yellow' }
                    'bloqueada'                { 'Red' }
                    'em_recuperacao'           { 'Magenta' }
                    default                    { 'DarkGray' }
                }
                Write-Host ('  [' + `$f.id + '] ' + `$f.nome.PadRight(30) + ' -> ' + `$f.status) -ForegroundColor `$cor
            }
        } catch {
            Write-Host 'Erro ao ler indice.json — aguardando...' -ForegroundColor Red
            Get-Content '$BacklogPath' -Encoding UTF8
        }
    } else {
        Write-Host 'indice.json ainda nao gerado.' -ForegroundColor DarkGray
        Write-Host 'Execute /fabricar-software para iniciar o pipeline.' -ForegroundColor Yellow
    }
    Start-Sleep 2
}
"@

# PAINEL 3 — Git log (atualiza a cada 5 segundos)
$Cmd3 = @"
chcp 65001 | Out-Null
Set-Location '$ProjectDir'
while (`$true) {
    Clear-Host
    Write-Host '[ GIT LOG — nt-usina ]' -ForegroundColor Cyan
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Gray
    Write-Host '-------------------------------------------'
    `$gitCheck = git rev-parse --git-dir 2>&1
    if (`$LASTEXITCODE -eq 0) {
        git log --oneline --graph --decorate --all -20
    } else {
        Write-Host 'Git ainda não inicializado neste diretório.' -ForegroundColor Gray
        Write-Host 'Execute: git init' -ForegroundColor Yellow
    }
    Start-Sleep 5
}
"@

# PAINEL 4 — Log da aplicação (tail em tempo real)
$Cmd4 = @"
chcp 65001 | Out-Null
Set-Location '$ProjectDir'
Write-Host '[ LOG DA APLICACAO ]' -ForegroundColor Cyan
Write-Host 'Monitorando: $AppLog' -ForegroundColor Gray
Write-Host '-------------------------------------------'
Get-Content '$AppLog' -Wait -Tail 50 -Encoding UTF8
"@

# -----------------------------------------------------------------------------
# Salva comandos de cada painel em arquivos temporários
# (evita problemas de escape de strings multi-linha no wt.exe)
# -----------------------------------------------------------------------------
$TmpDir = [System.IO.Path]::GetTempPath()
$Tmp1 = Join-Path $TmpDir "usina-pane1.ps1"
$Tmp2 = Join-Path $TmpDir "usina-pane2.ps1"
$Tmp3 = Join-Path $TmpDir "usina-pane3.ps1"
$Tmp4 = Join-Path $TmpDir "usina-pane4.ps1"

$utf8Bom = New-Object System.Text.UTF8Encoding $true
[System.IO.File]::WriteAllText($Tmp1, $Cmd1, $utf8Bom)
[System.IO.File]::WriteAllText($Tmp2, $Cmd2, $utf8Bom)
[System.IO.File]::WriteAllText($Tmp3, $Cmd3, $utf8Bom)
[System.IO.File]::WriteAllText($Tmp4, $Cmd4, $utf8Bom)

# -----------------------------------------------------------------------------
# Monta os argumentos do Windows Terminal
#
# Layout alvo (4 paineis iguais, 25% cada):
#   ┌──────────────────────┬──────────────────────┐
#   │  P1 - Claude Code    │  P2 - Backlog Monitor │
#   ├──────────────────────┼──────────────────────┤
#   │  P3 - Git Log        │  P4 - App Log         │
#   └──────────────────────┴──────────────────────┘
#
# Sequencia de splits:
#   new-tab            → P1 full (foco: P1)
#   split-pane -V 0.50 → P2 a direita de P1 (foco: P2)
#   move-focus left    → (foco: P1)
#   split-pane -H 0.50 → P3 abaixo de P1 (foco: P3)
#   move-focus right   → (foco: P2)
#   split-pane -H 0.50 → P4 abaixo de P2 (foco: P4)
#   move-focus previousInOrder → volta para P1
# -----------------------------------------------------------------------------
$PS = "powershell.exe"

$wtArgs = (
    "new-tab",
        "--title", '"Claude Code - nt-usina"',
        "-d", "`"$ProjectDir`"",
        $PS, "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$Tmp1`"",
    ";", "split-pane", "-V", "--size", "0.50",
        "--title", '"Backlog Monitor"',
        "-d", "`"$ProjectDir`"",
        $PS, "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$Tmp2`"",
    ";", "move-focus", "left",
    ";", "split-pane", "-H", "--size", "0.50",
        "--title", '"Git Log"',
        "-d", "`"$ProjectDir`"",
        $PS, "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$Tmp3`"",
    ";", "move-focus", "right",
    ";", "split-pane", "-H", "--size", "0.50",
        "--title", '"App Log"',
        "-d", "`"$ProjectDir`"",
        $PS, "-NoExit", "-ExecutionPolicy", "Bypass", "-File", "`"$Tmp4`"",
    ";", "move-focus", "previousInOrder"
)

# -----------------------------------------------------------------------------
# Inicia o Windows Terminal
# -----------------------------------------------------------------------------
Write-Host ""
Write-Host "Iniciando Natural Tecnologia — nt-usina..." -ForegroundColor Cyan
Write-Host "Projeto: $ProjectDir" -ForegroundColor Gray
Write-Host ""

Start-Process "wt.exe" -ArgumentList $wtArgs

Write-Host "✓ Windows Terminal aberto com 4 painéis." -ForegroundColor Green
Write-Host ""
Write-Host "  Painel 1 → Claude Code CLI" -ForegroundColor White
Write-Host "  Painel 2 → Backlog Monitor (backlog\indice.json)" -ForegroundColor White
Write-Host "  Painel 3 → Git log" -ForegroundColor White
Write-Host "  Painel 4 → Log: $AppLog" -ForegroundColor White
Write-Host ""
