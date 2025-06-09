<?php
//3_linux_tools_check.php
declare(strict_types=1);
set_time_limit(60);
ini_set('display_errors', '0');
error_reporting(0);

header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: GET");
header("Access-Control-Allow-Headers: Content-Type");
header("Cache-Control: no-store, no-cache, must-revalidate");
header("Pragma: no-cache");
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('X-Frame-Options: DENY');

final class LinuxToolsChecker
{
    private ?bool $procMounted = null;
    
    public function checkCommand(string $command): bool
    {
        try {
            $output = [];
            $exitCode = null;
            
            exec("command -v " . escapeshellcmd($command) . " 2>/dev/null", $output, $exitCode);
            
            return $exitCode === 0 && !empty($output);
        } catch (Throwable $e) {
            return false;
        }
    }
	
    public function checkFullLsof(): bool
    {
        try {
            if (!$this->checkCommand('lsof')) {
                return false;
            }

            $outputV = [];
            exec("lsof -v 2>&1", $outputV, $exitCodeV);
        
            $outputH = [];
            exec("lsof -h 2>&1", $outputH, $exitCodeH);
        
            $outputVString = implode("\n", $outputV);
            $outputHString = implode("\n", $outputH);
        
            $isVersionInfo = preg_match('/lsof version information:|revision:|copyright notice:/i', $outputVString);
        
            $isHelpInfo = preg_match('/usage:|options:|-- end option scan/i', $outputHString);
        
            return $isVersionInfo || $isHelpInfo;
        } catch (Throwable $e) {
            return false;
        }
    }

    public function checkProcMounted(): bool
    {
        if ($this->procMounted !== null) {
            return $this->procMounted;
        }

        try {
            $mounts = @file_get_contents('/proc/mounts');
            $this->procMounted = $mounts !== false && strpos($mounts, ' /proc ') !== false;
            return $this->procMounted;
        } catch (Throwable $e) {
            $this->procMounted = false;
            return false;
        }
    }

    public function checkProcFileAccess(string $file): bool
    {
        try {
            if (!$this->checkProcMounted()) {
                return false;
            }
        
            return $file === '/proc/self/exe' 
                || $file === '/proc/self/cmdline'
                ? (is_readable($file) && is_file($file))
                : false;
        } catch (Throwable $e) {
            return false;
        }
    }

    public function getCheckResults(): array
    {
        $procMounted = $this->checkProcMounted();
        
        return [
            'lsof' => $this->checkFullLsof(),
            'nohup' => $this->checkCommand('nohup'),
            'kill' => $this->checkCommand('kill'),
            '/proc_смонтирован' => $procMounted,
            '/proc_exe_чтение' => $procMounted ? $this->checkProcFileAccess('/proc/self/exe') : false,
            '/proc_cmdline_чтение' => $procMounted ? $this->checkProcFileAccess('/proc/self/cmdline') : false,
        ];
    }
}

try {
    $checker = new LinuxToolsChecker();
	http_response_code(200);
    echo json_encode(
        [
		    'результат' => true,
		    'утилиты_и_функции' => $checker->getCheckResults()
		], 
        JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
} catch (Throwable $e) {
	http_response_code(500);
    echo json_encode(
        [
            'результат' => false,
            'сообщение' => $e->getMessage(),
        ],
        JSON_PRETTY_PRINT | JSON_UNESCAPED_SLASHES | JSON_UNESCAPED_UNICODE
    );
}