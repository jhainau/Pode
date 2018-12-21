$path = $MyInvocation.MyCommand.Path
$src = (Split-Path -Parent -Path $path) -ireplace '[\\/]tests[\\/]unit[\\/]', '/src/'
Get-ChildItem "$($src)/*.ps1" | Resolve-Path | ForEach-Object { . $_ }

$PodeSession = @{ 'Server' = $null; }

Describe 'State' {
    Context 'Invalid parameters supplied' {
        It 'Throw null name parameter error' {
            { State -Action Set -Name $null } | Should Throw 'The argument is null or empty'
        }

        It 'Throw empty name parameter error' {
            { State -Action Set -Name ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }

        It 'Throw invalid action error' {
            { State -Action 'MOO' -Name 'test' } | Should Throw "Cannot validate argument on parameter 'Action'"
        }
    }

    Context 'Valid parameters supplied' {
        It 'Returns null for no session' {
            State -Action Set -Name 'test' | Should Be $null
        }

        It 'Returns null for no shared state in session' {
            $PodeSession.Server = @{ 'State' = $null }
            State -Action Set -Name 'test' | Should Be $null
        }

        It 'Sets and returns an object' {
            $PodeSession.Server = @{ 'State' = @{} }
            $result = State -Action Set -Name 'test' -Object 7

            $result | Should Be 7
            $PodeSession.Server.State['test'] | Should Be 7
        }

        It 'Gets an object' {
            $PodeSession.Server = @{ 'State' = @{ 'test' = 8 } }
            State -Action Get -Name 'test' | Should Be 8
        }

        It 'Removes an object' {
            $PodeSession.Server = @{ 'State' = @{ 'test' = 8 } }
            State -Action Remove -Name 'test' | Should Be 8
            $PodeSession.Server.State['test'] | Should Be $null
        }
    }
}

Describe 'Listen' {
    Context 'Invalid parameters supplied' {
        It 'Throw null IP:Port parameter error' {
            { Listen -IPPort $null -Type 'HTTP' } | Should Throw 'The argument is null or empty'
        }

        It 'Throw empty IP:Port parameter error' {
            { Listen -IPPort ([string]::Empty) -Type 'HTTP' } | Should Throw 'The argument is null or empty'
        }

        It 'Throw invalid type error for no method' {
            { Listen -IPPort '127.0.0.1' -Type 'MOO' } | Should Throw "Cannot validate argument on parameter 'Type'"
        }
    }

    Context 'Valid parameters supplied' {
        Mock Test-IPAddress { return $true }
        Mock Test-IsAdminUser { return $true }

        It 'Set just a Hostname address' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP 'foo.com' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].Name | Should Be ([string]::Empty)
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].RawAddress | Should Be 'foo.com'
        }

        It 'Set Hostname address with a Name' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP 'foo.com' -Type 'HTTP' -Name 'Example'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].Name | Should Be 'Example'
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be 'foo.com'
        }

        It 'Set just a Hostname address with colon' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP 'foo.com:' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].RawAddress | Should Be 'foo.com:'
        }

        It 'Set both the Hostname address and port' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP 'foo.com:80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'foo.com'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be 'foo.com'
        }

        It 'Set just an IPv4 address' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'
        }

        It 'Set just an IPv4 address for all' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP 'all' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '0.0.0.0'
            $PodeSession.Server.Endpoints[0].RawAddress | Should Be 'all'
        }

        It 'Set just an IPv4 address with colon' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 0
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'
        }

        It 'Set just a port' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '0.0.0.0'
        }

        It 'Set just a port with colon' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP ':80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '0.0.0.0'
        }

        It 'Set both IPv4 address and port' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'
        }

        It 'Set both IPv4 address and port for all' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '*:80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1
            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '0.0.0.0'
            $PodeSession.Server.Endpoints[0].RawAddress | Should Be '*:80'
        }

        It 'Throws error for an invalid IPv4' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            { Listen -IP '256.0.0.1' -Type 'HTTP' } | Should Throw 'Invalid IP Address'

            $PodeSession.Server.Type | Should Be $null
            $PodeSession.Server.Endpoints | Should Be $null
        }

        It 'Throws error for an invalid IPv4 address with port' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            { Listen -IP '256.0.0.1:80' -Type 'HTTP' } | Should Throw 'Invalid IP Address'

            $PodeSession.Server.Type | Should Be $null
            $PodeSession.Server.Endpoints | Should Be $null
        }

        It 'Add two endpoints to listen on, of the same type' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP'
            Listen -IP 'pode.foo.com:80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 2

            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'

            $PodeSession.Server.Endpoints[1].Port | Should Be 80
            $PodeSession.Server.Endpoints[1].HostName | Should Be 'pode.foo.com'
            $PodeSession.Server.Endpoints[1].Address.ToString() | Should Be 'pode.foo.com'
        }

        It 'Add two endpoints to listen on, with different names' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP' -Name 'Example1'
            Listen -IP 'pode.foo.com:80' -Type 'HTTP' -Name 'Example2'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 2

            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].Name | Should Be 'Example1'
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'

            $PodeSession.Server.Endpoints[1].Port | Should Be 80
            $PodeSession.Server.Endpoints[1].Name | Should Be 'Example2'
            $PodeSession.Server.Endpoints[1].HostName | Should Be 'pode.foo.com'
            $PodeSession.Server.Endpoints[1].Address.ToString() | Should Be 'pode.foo.com'
        }

        It 'Add two endpoints to listen on, one of HTTP and one of HTTPS' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP'
            Listen -IP 'pode.foo.com:80' -Type 'HTTPS'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 2

            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'

            $PodeSession.Server.Endpoints[1].Port | Should Be 80
            $PodeSession.Server.Endpoints[1].HostName | Should Be 'pode.foo.com'
            $PodeSession.Server.Endpoints[1].Address.ToString() | Should Be 'pode.foo.com'
        }

        It 'Add two endpoints to listen on, but one added as they are the same' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP'
            Listen -IP '127.0.0.1:80' -Type 'HTTP'

            $PodeSession.Server.Type | Should Be 'HTTP'
            $PodeSession.Server.Endpoints | Should Not Be $null
            $PodeSession.Server.Endpoints.Length | Should Be 1

            $PodeSession.Server.Endpoints[0].Port | Should Be 80
            $PodeSession.Server.Endpoints[0].HostName | Should Be 'localhost'
            $PodeSession.Server.Endpoints[0].Address.ToString() | Should Be '127.0.0.1'
        }

        It 'Throws error when adding two endpoints of different types' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP'
            { Listen -IP 'pode.foo.com:80' -Type 'SMTP' } | Should Throw 'cannot add smtp endpoint'
        }

        It 'Throws error when adding two endpoints with the same name' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'HTTP' -Name 'Example'
            { Listen -IP 'pode.foo.com:80' -Type 'HTTP' -Name 'Example' } | Should Throw 'already been defined'
        }

        It 'Throws error when adding two SMTP endpoints' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'SMTP'
            { Listen -IP 'pode.foo.com:80' -Type 'SMTP' } | Should Throw 'already been defined'
        }

        It 'Throws error when adding two TCP endpoints' {
            $PodeSession.Server = @{ 'Endpoints' = @(); 'Type' = $null }
            Listen -IP '127.0.0.1:80' -Type 'TCP'
            { Listen -IP 'pode.foo.com:80' -Type 'TCP' } | Should Throw 'already been defined'
        }
    }
}

Describe 'Script' {
    Context 'Invalid parameters supplied' {
        It 'Throw null path parameter error' {
            { Script -Path $null } | Should Throw 'The argument is null or empty'
        }

        It 'Throw empty path parameter error' {
            { Script -Path ([string]::Empty) } | Should Throw 'The argument is null or empty'
        }
    }

    Context 'Valid parameters supplied' {
        Mock 'Resolve-Path' { return 'c:/some/file.txt' }

        It 'Returns null for no shared state in session' {
            $PodeSession = @{ 'RunspacePools' = @{
                'Main' = @{
                    'InitialSessionState' = [initialsessionstate]::CreateDefault()
                }
            } }

            Script -Path 'file.txt'

            $modules = @($PodeSession.RunspacePools.Main.InitialSessionState.Modules)
            $modules.Length | Should Be 1
            $modules[0].Name | Should Be 'c:/some/file.txt'
        }
    }
}