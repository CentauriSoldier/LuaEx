'use strict';
const {spawn, execFile} = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

function request(files) {
    const parts = [Buffer.from(String(files.length) + '\n')];
    for (const item of files) {
        for (const value of [item.file, item.source]) {
            const data = Buffer.from(value.replace(/\r\n/g, '\n'), 'utf8');
            parts.push(Buffer.from(String(data.length) + '\n'), data);
        }
    }
    return Buffer.concat(parts);
}

class Runner {
    constructor() { this.jobs = new Set(); this.executables = new Map(); this.disposed = false; }

    async executable(configured) {
        if (this.executables.has(configured)) return this.executables.get(configured);
        const candidates = configured ? [configured] : [
            process.env.LUA54,
            path.join(os.homedir(), 'Sync/Portable Apps/Libraries/Lua/5.4/lua54.exe'),
            'lua54', 'lua5.4', 'lua'
        ].filter(Boolean);
        for (const candidate of candidates) {
            const version = await new Promise(resolve => {
                execFile(candidate, ['-e', 'io.write(_VERSION)'],
                    {encoding: 'utf8', timeout: 2000, windowsHide: true},
                    (error, stdout) => resolve(error ? '' : stdout.trim()));
            });
            if (version === 'Lua 5.4') { this.executables.set(configured, candidate); return candidate; }
        }
        throw new Error('Lua 5.4 is required. Set linter-lxc.luaExecutable to a Lua 5.4 executable (not Lua 5.3 or luac).');
    }

    async lint({executable, root, mode, files, timeout = 10000}) {
        const program = await this.executable(executable || '');
        if (this.disposed) throw new Error('Linter was deactivated.');
        return new Promise((resolve, reject) => {
            const child = spawn(program, [path.join(__dirname, '../lua/worker.lua'), root || '', mode],
                {windowsHide: true, shell: false, stdio: ['pipe', 'pipe', 'pipe']});
            this.jobs.add(child);
            child.stdout.setEncoding('utf8');
            child.stderr.setEncoding('utf8');
            let stdout = '', stderr = '', size = 0, completed = false;
            const finish = (error, result) => {
                if (completed) return;
                completed = true;
                clearTimeout(timer);
                this.jobs.delete(child);
                if (error) reject(error); else resolve(result);
            };
            const timer = setTimeout(() => {
                child.kill(); finish(new Error('Lua lint worker timed out; no application code was executed.'));
            }, timeout);
            child.stdout.on('data', data => {
                size += Buffer.byteLength(data, 'utf8');
                if (size > 2 * 1024 * 1024) { child.kill(); finish(new Error('Lint diagnostic output exceeded 2 MiB.')); }
                else stdout += data.toString('utf8');
            });
            child.stderr.on('data', data => { stderr = (stderr + data.toString('utf8')).slice(-8192); });
            child.stdin.on('error', error => { if (error.code !== 'EPIPE') finish(error); });
            child.on('error', error => finish(error));
            child.on('close', code => {
                if (code !== 0) return finish(new Error(stderr || 'Lua lint worker exited with status ' + code));
                try { const response = JSON.parse(stdout);
                    const diagnostics = Array.isArray(response) ? response : response.diagnostics;
                    if (!Array.isArray(diagnostics)) throw new Error('Missing diagnostic list.');
                    diagnostics.classNames = response.classNames || [];
                    finish(null, diagnostics); } catch (error) { finish(new Error('Invalid lint worker response: ' + error.message)); }
            });
            child.stdin.end(request(files));
        });
    }

    dispose() { this.disposed = true; for (const child of this.jobs) child.kill(); this.jobs.clear(); this.executables.clear(); }
}
module.exports = {Runner, request};
