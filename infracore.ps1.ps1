chcp 65001 > $null

Clear-Host

$Host.UI.RawUI.WindowTitle = "Infracore - Support Toolkit v3.0"

# ============================================================
# CONFIGURAÇÃO
# ============================================================

$logsPath = ".\logs"

if (!(Test-Path $logsPath)) {
    New-Item -ItemType Directory -Path $logsPath | Out-Null
}

$logFile = "$logsPath\activity.log"
$diagFile = "$logsPath\diagnostico.txt"

# ============================================================
# LOG SYSTEM
# ============================================================

function Write-Log {
    param (
        [string]$action,
        [string]$status
    )

    Add-Content $logFile "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$status] $action"
}

# ============================================================
# EXECUTOR PADRÃO (NOVA CAMADA PROFISSIONAL)
# ============================================================

function Execute-Task {
    param (
        [string]$title,
        [scriptblock]$command
    )

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkRed
    Write-Host " $title" -ForegroundColor Yellow
    Write-Host "============================================================" -ForegroundColor DarkRed
    Write-Host ""

    try {
        & $command
        Write-Host ""
        Write-Host "[OK] Operacao concluida com sucesso" -ForegroundColor Green
        Write-Log $title "SUCCESS"
    }
    catch {
        Write-Host ""
        Write-Host "[ERRO] Falha na execucao: $_" -ForegroundColor Red
        Write-Log $title "ERROR - $_"
    }

    Write-Host ""
    Pause
}

# ============================================================
# MENU
# ============================================================

function Show-Menu {

    Clear-Host

    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "                     Infracore                            " -ForegroundColor Red
    Write-Host "              Automacao para Suporte TI                  " -ForegroundColor Gray
    Write-Host ""
    Write-Host "============================================================" -ForegroundColor DarkRed
    Write-Host ""

    Write-Host "[ CONEXAO ]" -ForegroundColor Cyan
    Write-Host "[1]  Limpar DNS" -ForegroundColor White
    Write-Host "[2]  Renovar IP" -ForegroundColor White
    Write-Host "[6]  Testar Internet" -ForegroundColor White
    Write-Host "[7]  Mostrar IP da Maquina" -ForegroundColor White
    Write-Host "[15] Reiniciar Rede (Winsock + IP Reset)" -ForegroundColor White
    Write-Host "[16] Ping para Google" -ForegroundColor White

    Write-Host ""

    Write-Host "[ SISTEMA ]" -ForegroundColor Cyan
    Write-Host "[4]  Informacoes do Sistema" -ForegroundColor White
    Write-Host "[8]  Ver Uso de Memoria" -ForegroundColor White
    Write-Host "[9]  Ver Espaco em Disco" -ForegroundColor White
    Write-Host "[14] Ver Usuarios Logados" -ForegroundColor White

    Write-Host ""

    Write-Host "[ MANUTENCAO E REPAROS ]" -ForegroundColor Cyan
    Write-Host "[3]  Limpar Arquivos Temp" -ForegroundColor White
    Write-Host "[5]  Reiniciar Spooler" -ForegroundColor White
    Write-Host "[13] Exportar Diagnostico Completo" -ForegroundColor White

    Write-Host ""

    Write-Host "[ FERRAMENTAS ]" -ForegroundColor Cyan
    Write-Host "[10] Abrir Gerenciador de Tarefas" -ForegroundColor White
    Write-Host "[11] Abrir Servicos" -ForegroundColor White
    Write-Host "[12] Abrir Painel de Controle" -ForegroundColor White

    Write-Host ""

    Write-Host "[0]  Sair" -ForegroundColor Red
    Write-Host ""
}

# ============================================================
# LOOP PRINCIPAL
# ============================================================

do {

    Show-Menu
    $option = Read-Host "Escolha uma opcao"

    switch ($option) {

        # ========================
        # CONEXAO
        # ========================

        "1" { Execute-Task "Limpeza de DNS" { ipconfig /flushdns } }

        "2" { Execute-Task "Renovacao de IP" {
                ipconfig /release
                ipconfig /renew
            }
        }

        "6" { Execute-Task "Teste de Conexao Internet" {
                Test-Connection 8.8.8.8 -Count 3
            }
        }

        "7" { Execute-Task "Exibicao de IP da Maquina" { ipconfig } }

        "15" { Execute-Task "Reset Completo de Rede" {
                ipconfig /flushdns
                netsh winsock reset
                netsh int ip reset
            }
        }

        "16" { Execute-Task "Ping Google DNS" { ping google.com } }

        # ========================
        # SISTEMA
        # ========================

        "4" { Execute-Task "Informacoes do Sistema" { systeminfo } }

        "8" { Execute-Task "Uso de Memoria RAM" {
                Get-CimInstance Win32_OperatingSystem |
                Select-Object @{
                    Name="RAM Livre (GB)";
                    Expression={"{0:N2}" -f ($_.FreePhysicalMemory / 1MB)}
                },
                @{
                    Name="RAM Total (GB)";
                    Expression={"{0:N2}" -f ($_.TotalVisibleMemorySize / 1MB)}
                }
            }
        }

        "9" { Execute-Task "Espaco em Disco" {
                Get-PSDrive -PSProvider FileSystem
            }
        }

        "14" { Execute-Task "Usuarios Logados no Sistema" { query user } }

        # ========================
        # MANUTENCAO E REPAROS 
        # ========================

        "3" { Execute-Task "Limpeza de Arquivos Temporarios" {
                Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
                Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            }
        }

        "5" { Execute-Task "Reinicio do Spooler de Impressao" {
                net stop spooler
                net start spooler
            }
        }

        "13" { Execute-Task "Exportacao de Diagnostico Completo" {

                "================ DIAGNOSTICO MUNDIAL SA v3.0 ================" | Out-File $diagFile
                "" | Out-File $diagFile -Append

                "DATA:" | Out-File $diagFile -Append
                Get-Date | Out-File $diagFile -Append

                "" | Out-File $diagFile -Append

                "HOSTNAME:" | Out-File $diagFile -Append
                hostname | Out-File $diagFile -Append

                "" | Out-File $diagFile -Append

                "IPCONFIG:" | Out-File $diagFile -Append
                ipconfig | Out-File $diagFile -Append

                "" | Out-File $diagFile -Append

                "SISTEMA:" | Out-File $diagFile -Append
                systeminfo | Out-File $diagFile -Append

                "" | Out-File $diagFile -Append

                "DISCO:" | Out-File $diagFile -Append
                Get-PSDrive -PSProvider FileSystem | Out-File $diagFile -Append

                "" | Out-File $diagFile -Append

                "MEMORIA:" | Out-File $diagFile -Append
                Get-CimInstance Win32_OperatingSystem | Out-File $diagFile -Append
            }
        }

        # ========================
        # FERRAMENTAS
        # ========================

        "10" { taskmgr }

        "11" { services.msc }

        "12" { control }

        # ========================
        # SAIR
        # ========================

        "0" {
            Clear-Host
            Write-Host "Encerrando Mundial SA Toolkit..." -ForegroundColor Red
            Start-Sleep 1
        }

        default {
            Write-Host ""
            Write-Host "Opcao invalida. Tente novamente." -ForegroundColor Red
            Start-Sleep 1
        }
    }

} while ($option -ne "0")