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
Clear-Host
Write-Host '╔══════════════════════════════════════════╗' -ForegroundColor Cyan
Write-Host '║   Natural Tecnologia — nt-usina          ║' -ForegroundColor Cyan
Write-Host '║   Fábrica de Software IA                 ║' -ForegroundColor Cyan
Write-Host '╚══════════════════════════════════════════╝' -ForegroundColor Cyan
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

# PAINEL 2 — Backlog Monitor (atualiza a cada 2 segundos)
$Cmd2 = @"
Set-Location '$ProjectDir'
while (`$true) {
    Clear-Host
    Write-Host '[ BACKLOG — nt-usina ]' -ForegroundColor Cyan
    Write-Host (Get-Date -Format 'yyyy-MM-dd HH:mm:ss') -ForegroundColor Gray
    Write-Host '-------------------------------------------'
    if (Test-Path '$BacklogPath') {
        try {
            `$json = Get-Content '$BacklogPath' -Raw -Encoding UTF8 | ConvertFrom-Json
            Write-Host ('Status pipeline: ' + `$json.status) -ForegroundColor Yellow
            Write-Host ('Features total:  ' + `$json.features.Count)
            `$grupos = `$json.features | Group-Object status
            foreach (`$g in `$grupos) {
                `$cor = switch (`$g.Name) {
                    'concluida'               { 'Green' }
                    'em_desenvolvimento'      { 'Cyan' }
                    'em_testes'               { 'Yellow' }
                    'bloqueada'               { 'Red' }
                    'em_recuperacao'          { 'Magenta' }
                    default                   { 'Gray' }
                }
                Write-Host ('  ' + `$g.Name + ': ' + `$g.Count) -ForegroundColor `$cor
            }
            Write-Host ''
            Write-Host '--- Features ---'
            foreach (`$f in `$json.features) {
                `$cor = switch (`$f.status) {
                    'concluida'          { 'Green' }
                    'em_desenvolvimento' { 'Cyan' }
                    'em_testes'         { 'Yellow' }
                    'bloqueada'         { 'Red' }
                    default             { 'Gray' }
                }
                Write-Host ('  [' + `$f.id + '] ' + `$f.nome + ' → ' + `$f.status) -ForegroundColor `$cor
            }
        } catch {
            Get-Content '$BacklogPath' -Encoding UTF8
        }
    } else {
        Write-Host 'indice.json ainda não gerado.' -ForegroundColor Gray
    }
    Start-Sleep 2
}
"@

# PAINEL 3 — Git log (atualiza a cada 5 segundos)
$Cmd3 = @"
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
Set-Location '$ProjectDir'
Write-Host '[ LOG DA APLICAÇÃO ]' -ForegroundColor Cyan
Write-Host 'Monitorando: $AppLog' -ForegroundColor Gray
Write-Host '-------------------------------------------'
Get-Content '$AppLog' -Wait -Tail 50 -Encoding UTF8
"@

# -----------------------------------------------------------------------------
# Monta os argumentos do Windows Terminal
# Ordem: new-tab (P1) → split -H (P2) → move left → split -V (P3) → right → split -V (P4)
# -----------------------------------------------------------------------------
$PS = "powershell.exe"

$wtArgs = (
    "new-tab",
        "--title", "Claude Code | nt-usina",
        "-d", $ProjectDir,
        $PS, "-NoExit", "-Command", $Cmd1,
    ";", "split-pane", "-H", "--size", "0.40",
        "--title", "Backlog Monitor",
        "-d", $ProjectDir,
        $PS, "-NoExit", "-Command", $Cmd2,
    ";", "move-focus", "left",
    ";", "split-pane", "-V", "--size", "0.35",
        "--title", "Git Log",
        "-d", $ProjectDir,
        $PS, "-NoExit", "-Command", $Cmd3,
    ";", "move-focus", "right",
    ";", "split-pane", "-V", "--size", "0.35",
        "--title", "App Log",
        "-d", $ProjectDir,
        $PS, "-NoExit", "-Command", $Cmd4,
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
