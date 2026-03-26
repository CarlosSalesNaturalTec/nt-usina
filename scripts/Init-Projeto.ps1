# Init-Projeto.ps1
# Natural Tecnologia — nt-usina
# Inicializa a estrutura de diretórios e arquivos base para um novo projeto.
# Execute uma vez ao começar um novo projeto neste repositório.

param(
    [string]$NomeProjeto = "",
    [string]$Cliente = ""
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $PSScriptRoot

Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Natural Tecnologia — nt-usina" -ForegroundColor Cyan
Write-Host "  Inicializador de Projeto" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""

# --- Coletar informações se não fornecidas como parâmetros ---
if (-not $NomeProjeto) {
    $NomeProjeto = Read-Host "Nome do projeto (ex: sistema-vendas)"
}
if (-not $Cliente) {
    $Cliente = Read-Host "Nome do cliente"
}

$DataInicio = Get-Date -Format "yyyy-MM-dd"

# --- Criar estrutura de diretórios ---
Write-Host ""
Write-Host "[1/4] Criando estrutura de diretórios..." -ForegroundColor Yellow

$Dirs = @(
    "docs\demanda",
    "docs\bugs",
    "docs\testes",
    "backlog"
)

foreach ($Dir in $Dirs) {
    $FullPath = Join-Path $Root $Dir
    if (-not (Test-Path $FullPath)) {
        New-Item -ItemType Directory -Path $FullPath -Force | Out-Null
        Write-Host "  Criado: $Dir" -ForegroundColor Green
    } else {
        Write-Host "  Existe: $Dir" -ForegroundColor Gray
    }
}

# --- Criar demanda-cliente.md se não existir ---
Write-Host ""
Write-Host "[2/4] Preparando arquivo de demanda do cliente..." -ForegroundColor Yellow

$DemandaPath = Join-Path $Root "docs\demanda\demanda-cliente.md"
if (-not (Test-Path $DemandaPath)) {
    $DemandaContent = @"
# Demanda do Cliente — $NomeProjeto

> Cliente: $Cliente
> Data: $DataInicio
> Versão: 1.0

---

## Contexto

[Descreva aqui o contexto do negócio do cliente e o problema que precisa ser resolvido.]

## O que precisa ser desenvolvido

[Descreva em linguagem de negócio o que o sistema deve fazer.
Seja específico sobre funcionalidades, fluxos e restrições.
Não é necessário ser técnico — o agente PO interpretará e estruturará em user stories.]

## Atores do sistema

[Quem vai usar o sistema? Ex: administrador, cliente final, gestor, sistema externo]

## Restrições e observações

[Limitações de prazo, tecnologia preferida, integrações obrigatórias, etc.]

## Referências

[Links, documentos, prints de tela ou qualquer material auxiliar]
"@
    Set-Content -Path $DemandaPath -Value $DemandaContent -Encoding UTF8
    Write-Host "  Criado: docs\demanda\demanda-cliente.md" -ForegroundColor Green
    Write-Host "  → EDITE este arquivo com a demanda real antes de executar /fabricar-software" -ForegroundColor Cyan
} else {
    Write-Host "  Existe: docs\demanda\demanda-cliente.md (não sobrescrito)" -ForegroundColor Gray
}

# --- Inicializar backlog\indice.json ---
Write-Host ""
Write-Host "[3/4] Inicializando estado do pipeline..." -ForegroundColor Yellow

$IndicePath = Join-Path $Root "backlog\indice.json"
if (-not (Test-Path $IndicePath)) {
    $IndiceContent = @{
        status = "aguardando_inicializacao"
        projeto = $NomeProjeto
        cliente = $Cliente
        data_inicio = $DataInicio
        features = @()
    } | ConvertTo-Json -Depth 3
    Set-Content -Path $IndicePath -Value $IndiceContent -Encoding UTF8
    Write-Host "  Criado: backlog\indice.json" -ForegroundColor Green
} else {
    Write-Host "  Existe: backlog\indice.json (não sobrescrito)" -ForegroundColor Gray
}

# --- Criar docs\pipeline.log ---
$LogPath = Join-Path $Root "docs\pipeline.log"
if (-not (Test-Path $LogPath)) {
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Set-Content -Path $LogPath -Value "[$Timestamp] [INFO] [SISTEMA] Pipeline inicializado — Projeto: $NomeProjeto | Cliente: $Cliente" -Encoding UTF8
    Write-Host "  Criado: docs\pipeline.log" -ForegroundColor Green
} else {
    Write-Host "  Existe: docs\pipeline.log (não sobrescrito)" -ForegroundColor Gray
}

# --- Verificar pré-requisitos ---
Write-Host ""
Write-Host "[4/4] Verificando pré-requisitos..." -ForegroundColor Yellow

# Git
try {
    $GitStatus = git -C $Root rev-parse --git-dir 2>&1
    Write-Host "  Git: OK" -ForegroundColor Green
} catch {
    Write-Host "  Git: NAO INICIALIZADO — execute: git init && git commit --allow-empty -m 'chore: init'" -ForegroundColor Red
}

# GitHub CLI
try {
    $GhVersion = gh --version 2>&1 | Select-Object -First 1
    Write-Host "  GitHub CLI: OK ($GhVersion)" -ForegroundColor Green
} catch {
    Write-Host "  GitHub CLI: nao encontrado — instale em https://cli.github.com/" -ForegroundColor Yellow
}

# Claude Code CLI
try {
    $ClaudeVersion = claude --version 2>&1
    Write-Host "  Claude Code: OK ($ClaudeVersion)" -ForegroundColor Green
} catch {
    Write-Host "  Claude Code: nao encontrado — instale via npm install -g @anthropic-ai/claude-code" -ForegroundColor Red
}

# --- Resumo ---
Write-Host ""
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host "  Projeto inicializado!" -ForegroundColor Green
Write-Host "=================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Próximos passos:" -ForegroundColor White
Write-Host ""
Write-Host "  1. Edite: docs\demanda\demanda-cliente.md" -ForegroundColor Cyan
Write-Host "     (preencha com a demanda real do cliente)" -ForegroundColor Gray
Write-Host ""
Write-Host "  2. Inicie o pipeline:" -ForegroundColor Cyan
Write-Host "     claude   (abrir Claude Code CLI)" -ForegroundColor Gray
Write-Host "     /fabricar-software" -ForegroundColor Gray
Write-Host ""
Write-Host "  Ou inicie com o ambiente completo:" -ForegroundColor Cyan
Write-Host "     .\scripts\Start-Usina.ps1" -ForegroundColor Gray
Write-Host ""
