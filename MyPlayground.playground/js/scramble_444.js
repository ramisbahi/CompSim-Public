'use strict';

var isInWorker = (typeof WorkerGlobalScope !== 'undefined' && self instanceof WorkerGlobalScope);

function execBoth(funcMain, funcWorker, params) {
    if (!isInWorker && funcMain) {
        return funcMain.apply(this, params || []);
    }
    if (isInWorker && funcWorker) {
        return funcWorker.apply(this, params || []);
    }
    return {};
}

//execute function only in worker
function execWorker(func, params) {
    return execBoth(undefined, func, params);
}

//execute function only in main
function execMain(func, params) {
    return execBoth(func, undefined, params);
}

"use strict";

var mathlib = (function() {
    var Cnk = [],
        fact = [1];
    for (var i = 0; i < 32; ++i) {
        Cnk[i] = [];
        for (var j = 0; j < 32; ++j) {
            Cnk[i][j] = 0;
        }
    }
    for (var i = 0; i < 32; ++i) {
        Cnk[i][0] = Cnk[i][i] = 1;
        fact[i + 1] = fact[i] * (i + 1);
        for (var j = 1; j < i; ++j) {
            Cnk[i][j] = Cnk[i - 1][j - 1] + Cnk[i - 1][j];
        }
    }

    function circleOri(arr, a, b, c, d, ori) {
        var temp = arr[a];
        arr[a] = arr[d] ^ ori;
        arr[d] = arr[c] ^ ori;
        arr[c] = arr[b] ^ ori;
        arr[b] = temp ^ ori;
    }

    function circle(arr) {
        var length = arguments.length - 1,
            temp = arr[arguments[length]];
        for (var i = length; i > 1; i--) {
            arr[arguments[i]] = arr[arguments[i - 1]];
        }
        arr[arguments[1]] = temp;
        return circle;
    }

    //perm: [idx1, idx2, ..., idxn]
    //pow: 1, 2, 3, ...
    //ori: ori1, ori2, ..., orin, base
    // arr[perm[idx2]] = arr[perm[idx1]] + ori[idx2] - ori[idx1] + base
    function acycle(arr, perm, pow, ori) {
        pow = pow || 1;
        var plen = perm.length;
        var tmp = [];
        for (var i = 0; i < plen; i++) {
            tmp[i] = arr[perm[i]];
        }
        for (var i = 0; i < plen; i++) {
            var j = (i + pow) % plen;
            arr[perm[j]] = tmp[i];
            if (ori) {
                arr[perm[j]] += ori[j] - ori[i] + ori[ori.length - 1];
            }
        }
        return acycle;
    }

    function getPruning(table, index) {
        return table[index >> 3] >> ((index & 7) << 2) & 15;
    }

    function setNPerm(arr, idx, n) {
        var i, j;
        arr[n - 1] = 0;
        for (i = n - 2; i >= 0; --i) {
            arr[i] = idx % (n - i);
            idx = ~~(idx / (n - i));
            for (j = i + 1; j < n; ++j) {
                arr[j] >= arr[i] && ++arr[j];
            }
        }
    }

    function getNPerm(arr, n) {
        var i, idx, j;
        idx = 0;
        for (i = 0; i < n; ++i) {
            idx *= n - i;
            for (j = i + 1; j < n; ++j) {
                arr[j] < arr[i] && ++idx;
            }
        }
        return idx;
    }

    function getNParity(idx, n) {
        var i, p;
        p = 0;
        for (i = n - 2; i >= 0; --i) {
            p ^= idx % (n - i);
            idx = ~~(idx / (n - i));
        }
        return p & 1;
    }

    function get8Perm(arr, n, even) {
        n = n || 8;
        var idx = 0;
        var val = 0x76543210;
        for (var i = 0; i < n - 1; ++i) {
            var v = arr[i] << 2;
            idx = (n - i) * idx + (val >> v & 7);
            val -= 0x11111110 << v;
        }
        return even < 0 ? (idx >> 1) : idx;
    }

    function set8Perm(arr, idx, n, even) {
        n = (n || 8) - 1;
        var val = 0x76543210;
        var prt = 0;
        if (even < 0) {
            idx <<= 1;
        }
        for (var i = 0; i < n; ++i) {
            var p = fact[n - i];
            var v = ~~(idx / p);
            prt ^= v;
            idx %= p;
            v <<= 2;
            arr[i] = val >> v & 7;
            var m = (1 << v) - 1;
            val = (val & m) + (val >> 4 & ~m);
        }
        if (even < 0 && (prt & 1) != 0) {
            arr[n] = arr[n - 1];
            arr[n - 1] = val & 7;
        } else {
            arr[n] = val & 7;
        }
        return arr;
    }

    function getNOri(arr, n, evenbase) {
        var base = Math.abs(evenbase);
        var idx = evenbase < 0 ? 0 : arr[0] % base;
        for (var i = n - 1; i > 0; i--) {
            idx = idx * base + arr[i] % base;
        }
        return idx;
    }

    function setNOri(arr, idx, n, evenbase) {
        var base = Math.abs(evenbase);
        var parity = base * n;
        for (var i = 1; i < n; i++) {
            arr[i] = idx % base;
            parity -= arr[i];
            idx = ~~(idx / base);
        }
        arr[0] = (evenbase < 0 ? parity : idx) % base;
        return arr;
    }

    // type: 'p', 'o'
    // evenbase: base for ori, sign for even parity
    function coord(type, length, evenbase) {
        this.length = length;
        this.evenbase = evenbase;
        this.get = type == 'p' ?
            function(arr) {
                return get8Perm(arr, this.length, this.evenbase);
            } : function(arr) {
                return getNOri(arr, this.length, this.evenbase);
            };
        this.set = type == 'p' ?
            function(arr, idx) {
                return set8Perm(arr, idx, this.length, this.evenbase);
            } : function(arr, idx) {
                return setNOri(arr, idx, this.length, this.evenbase);
            };
    }

    function fillFacelet(facelets, f, perm, ori, divcol) {
        for (var i = 0; i < facelets.length; i++) {
            for (var j = 0; j < facelets[i].length; j++) {
                f[facelets[i][(j + ori[i]) % facelets[i].length]] = ~~(facelets[perm[i]][j] / divcol);
            }
        }
    }

    function createMove(moveTable, size, doMove, N_MOVES) {
        N_MOVES = N_MOVES || 6;
        if ($.isArray(doMove)) {
            var cord = new coord(doMove[1], doMove[2], doMove[3]);
            doMove = doMove[0];
            for (var j = 0; j < N_MOVES; j++) {
                moveTable[j] = [];
                for (var i = 0; i < size; i++) {
                    var arr = cord.set([], i);
                    doMove(arr, j);
                    moveTable[j][i] = cord.get(arr);
                }
            }
        } else {
            for (var j = 0; j < N_MOVES; j++) {
                moveTable[j] = [];
                for (var i = 0; i < size; i++) {
                    moveTable[j][i] = doMove(i, j);
                }
            }
        }
    }

    function edgeMove(arr, m) {
        if (m == 0) { //F
            circleOri(arr, 0, 7, 8, 4, 1);
        } else if (m == 1) { //R
            circleOri(arr, 3, 6, 11, 7, 0);
        } else if (m == 2) { //U
            circleOri(arr, 0, 1, 2, 3, 0);
        } else if (m == 3) { //B
            circleOri(arr, 2, 5, 10, 6, 1);
        } else if (m == 4) { //L
            circleOri(arr, 1, 4, 9, 5, 0);
        } else if (m == 5) { //D
            circleOri(arr, 11, 10, 9, 8, 0);
        }
    }

    function CubieCube() {
        this.ca = [0, 1, 2, 3, 4, 5, 6, 7];
        this.ea = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];
    }

    CubieCube.EdgeMult = function(a, b, prod) {
        for (var ed = 0; ed < 12; ed++) {
            prod.ea[ed] = a.ea[b.ea[ed] >> 1] ^ (b.ea[ed] & 1);
        }
    };

    CubieCube.CornMult = function(a, b, prod) {
        for (var corn = 0; corn < 8; corn++) {
            var ori = ((a.ca[b.ca[corn] & 7] >> 3) + (b.ca[corn] >> 3)) % 3;
            prod.ca[corn] = a.ca[b.ca[corn] & 7] & 7 | ori << 3;
        }
    };

    CubieCube.CubeMult = function(a, b, prod) {
        CubieCube.CornMult(a, b, prod);
        CubieCube.EdgeMult(a, b, prod);
    };

    CubieCube.prototype.init = function(ca, ea) {
        this.ca = ca.slice();
        this.ea = ea.slice();
        return this;
    };

    CubieCube.prototype.isEqual = function(c) {
        for (var i = 0; i < 8; i++) {
            if (this.ca[i] != c.ca[i]) {
                return false;
            }
        }
        for (var i = 0; i < 12; i++) {
            if (this.ea[i] != c.ea[i]) {
                return false;
            }
        }
        return true;
    };

    var cornerFacelet = [
        [8, 9, 20],
        [6, 18, 38],
        [0, 36, 47],
        [2, 45, 11],
        [29, 26, 15],
        [27, 44, 24],
        [33, 53, 42],
        [35, 17, 51]
    ];
    var edgeFacelet = [
        [5, 10],
        [7, 19],
        [3, 37],
        [1, 46],
        [32, 16],
        [28, 25],
        [30, 43],
        [34, 52],
        [23, 12],
        [21, 41],
        [50, 39],
        [48, 14]
    ];

    CubieCube.prototype.toFaceCube = function(cFacelet, eFacelet) {
        cFacelet = cFacelet || cornerFacelet;
        eFacelet = eFacelet || edgeFacelet;
        var ts = "URFDLB";
        var f = [];
        for (var i = 0; i < 54; i++) {
            f[i] = ts[~~(i / 9)];
        }
        for (var c = 0; c < 8; c++) {
            var j = this.ca[c] & 0x7; // cornercubie with index j is at
            var ori = this.ca[c] >> 3; // Orientation of this cubie
            for (var n = 0; n < 3; n++)
                f[cFacelet[c][(n + ori) % 3]] = ts[~~(cFacelet[j][n] / 9)];
        }
        for (var e = 0; e < 12; e++) {
            var j = this.ea[e] >> 1; // edgecubie with index j is at edgeposition
            var ori = this.ea[e] & 1; // Orientation of this cubie
            for (var n = 0; n < 2; n++)
                f[eFacelet[e][(n + ori) % 2]] = ts[~~(eFacelet[j][n] / 9)];
        }
        return f.join("");
    }

    CubieCube.prototype.invFrom = function(cc) {
        for (var edge = 0; edge < 12; edge++) {
            this.ea[cc.ea[edge] >> 1] = edge << 1 | cc.ea[edge] & 1;
        }
        for (var corn = 0; corn < 8; corn++) {
            this.ca[cc.ca[corn] & 0x7] = corn | 0x20 >> (cc.ca[corn] >> 3) & 0x18;
        }
        return this;
    }

    CubieCube.prototype.fromFacelet = function(facelet, cFacelet, eFacelet) {
        cFacelet = cFacelet || cornerFacelet;
        eFacelet = eFacelet || edgeFacelet;
        var count = 0;
        var f = [];
        var centers = facelet[4] + facelet[13] + facelet[22] + facelet[31] + facelet[40] + facelet[49];
        for (var i = 0; i < 54; ++i) {
            f[i] = centers.indexOf(facelet[i]);
            if (f[i] == -1) {
                return -1;
            }
            count += 1 << (f[i] << 2);
        }
        if (count != 0x999999) {
            return -1;
        }
        var col1, col2, i, j, ori;
        for (i = 0; i < 8; ++i) {
            for (ori = 0; ori < 3; ++ori)
                if (f[cFacelet[i][ori]] == 0 || f[cFacelet[i][ori]] == 3)
                    break;
            col1 = f[cFacelet[i][(ori + 1) % 3]];
            col2 = f[cFacelet[i][(ori + 2) % 3]];
            for (j = 0; j < 8; ++j) {
                if (col1 == ~~(cFacelet[j][1] / 9) && col2 == ~~(cFacelet[j][2] / 9)) {
                    this.ca[i] = j | ori % 3 << 3;
                    break;
                }
            }
        }
        for (i = 0; i < 12; ++i) {
            for (j = 0; j < 12; ++j) {
                if (f[eFacelet[i][0]] == ~~(eFacelet[j][0] / 9) && f[eFacelet[i][1]] == ~~(eFacelet[j][1] / 9)) {
                    this.ea[i] = j << 1;
                    break;
                }
                if (f[eFacelet[i][0]] == ~~(eFacelet[j][1] / 9) && f[eFacelet[i][1]] == ~~(eFacelet[j][0] / 9)) {
                    this.ea[i] = j << 1 | 1;
                    break;
                }
            }
        }
        return this;
    }

    var moveCube = [];
    for (var i = 0; i < 18; i++) {
        moveCube[i] = new CubieCube();
    }
    moveCube[0].init([3, 0, 1, 2, 4, 5, 6, 7], [6, 0, 2, 4, 8, 10, 12, 14, 16, 18, 20, 22]);
    moveCube[3].init([20, 1, 2, 8, 15, 5, 6, 19], [16, 2, 4, 6, 22, 10, 12, 14, 8, 18, 20, 0]);
    moveCube[6].init([9, 21, 2, 3, 16, 12, 6, 7], [0, 19, 4, 6, 8, 17, 12, 14, 3, 11, 20, 22]);
    moveCube[9].init([0, 1, 2, 3, 5, 6, 7, 4], [0, 2, 4, 6, 10, 12, 14, 8, 16, 18, 20, 22]);
    moveCube[12].init([0, 10, 22, 3, 4, 17, 13, 7], [0, 2, 20, 6, 8, 10, 18, 14, 16, 4, 12, 22]);
    moveCube[15].init([0, 1, 11, 23, 4, 5, 18, 14], [0, 2, 4, 23, 8, 10, 12, 21, 16, 18, 7, 15]);
    for (var a = 0; a < 18; a += 3) {
        for (var p = 0; p < 2; p++) {
            CubieCube.EdgeMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
            CubieCube.CornMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
        }
    }

    CubieCube.moveCube = moveCube;

    CubieCube.prototype.edgeCycles = function() {
        var visited = [];
        var small_cycles = [0, 0, 0];
        var cycles = 0;
        var parity = false;
        for (var x = 0; x < 12; ++x) {
            if (visited[x]) {
                continue
            }
            var length = -1;
            var flip = false;
            var y = x;
            do {
                visited[y] = true;
                ++length;
                flip ^= this.ea[y] & 1;
                y = this.ea[y] >> 1;
            } while (y != x);
            cycles += length >> 1;
            if (length & 1) {
                parity = !parity;
                ++cycles;
            }
            if (flip) {
                if (length == 0) {
                    ++small_cycles[0];
                } else if (length & 1) {
                    small_cycles[2] ^= 1;
                } else {
                    ++small_cycles[1];
                }
            }
        }
        small_cycles[1] += small_cycles[2];
        if (small_cycles[0] < small_cycles[1]) {
            cycles += (small_cycles[0] + small_cycles[1]) >> 1;
        } else {
            var flip_cycles = [0, 2, 3, 5, 6, 8, 9];
            cycles += small_cycles[1] + flip_cycles[(small_cycles[0] - small_cycles[1]) >> 1];
        }
        return cycles - parity;
    };

    function createPrun(prun, init, size, maxd, doMove, N_MOVES, N_POWER, N_INV) {
        var isMoveTable = $.isArray(doMove);
        N_MOVES = N_MOVES || 6;
        N_POWER = N_POWER || 3;
        N_INV = N_INV || 256;
        maxd = maxd || 256;
        for (var i = 0, len = (size + 7) >>> 3; i < len; i++) {
            prun[i] = -1;
        }
        prun[init >> 3] ^= 15 << ((init & 7) << 2);
        var val = 0;
        // var t = +new Date;
        for (var l = 0; l <= maxd; l++) {
            var done = 0;
            var inv = l >= N_INV;
            var fill = (l + 1) ^ 15;
            var find = inv ? 0xf : l;
            var check = inv ? l : 0xf;

            out: for (var p = 0; p < size; p++, val >>= 4) {
                if ((p & 7) == 0) {
                    val = prun[p >> 3];
                    if (!inv && val == -1) {
                        p += 7;
                        continue;
                    }
                }
                if ((val & 0xf) != find) {
                    continue;
                }
                for (var m = 0; m < N_MOVES; m++) {
                    var q = p;
                    for (var c = 0; c < N_POWER; c++) {
                        q = isMoveTable ? doMove[m][q] : doMove(q, m);
                        if (getPruning(prun, q) != check) {
                            continue;
                        }
                        ++done;
                        if (inv) {
                            prun[p >> 3] ^= fill << ((p & 7) << 2);
                            continue out;
                        }
                        prun[q >> 3] ^= fill << ((q & 7) << 2);
                    }
                }
            }
            if (done == 0) {
                break;
            }
            DEBUG && console.log('[prun]', done);
        }
    }

    //state_params: [[init, doMove, size, [maxd], [N_INV]], [...]...]
    function Solver(N_MOVES, N_POWER, state_params) {
        this.N_STATES = state_params.length;
        this.N_MOVES = N_MOVES;
        this.N_POWER = N_POWER;
        this.state_params = state_params;
        this.inited = false;
    }

    var _ = Solver.prototype;

    _.search = function(state, minl, MAXL) {
        MAXL = (MAXL || 99) + 1;
        if (!this.inited) {
            this.move = [];
            this.prun = [];
            for (var i = 0; i < this.N_STATES; i++) {
                var state_param = this.state_params[i];
                var init = state_param[0];
                var doMove = state_param[1];
                var size = state_param[2];
                var maxd = state_param[3];
                var N_INV = state_param[4];
                this.move[i] = [];
                this.prun[i] = [];
                createMove(this.move[i], size, doMove, this.N_MOVES);
                createPrun(this.prun[i], init, size, maxd, this.move[i], this.N_MOVES, this.N_POWER, N_INV);
            }
            this.inited = true;
        }
        this.sol = [];
        for (var maxl = minl; maxl < MAXL; maxl++) {
            if (this.idaSearch(state, maxl, -1)) {
                break;
            }
        }
        return maxl == MAXL ? null : this.sol.reverse();
    };

    _.toStr = function(sol, move_map, power_map) {
        var ret = [];
        for (var i = 0; i < sol.length; i++) {
            ret.push(move_map[sol[i][0]] + power_map[sol[i][1]]);
        }
        return ret.join(' ').replace(/ +/g, ' ');
    };

    _.idaSearch = function(state, maxl, lm) {
        var N_STATES = this.N_STATES;
        for (var i = 0; i < N_STATES; i++) {
            if (getPruning(this.prun[i], state[i]) > maxl) {
                return false;
            }
        }
        if (maxl == 0) {
            return true;
        }
        var offset = state[0] + maxl + lm + 1;
        for (var move0 = 0; move0 < this.N_MOVES; move0++) {
            var move = (move0 + offset) % this.N_MOVES;
            if (move == lm) {
                continue;
            }
            var cur_state = state.slice();
            for (var power = 0; power < this.N_POWER; power++) {
                for (var i = 0; i < N_STATES; i++) {
                    cur_state[i] = this.move[i][move][cur_state[i]];
                }
                if (this.idaSearch(cur_state, maxl - 1, move)) {
                    this.sol.push([move, power]);
                    return true;
                }
            }
        }
        return false;
    };

    function identity(state) {
        return state;
    }

    // state: string not null
    // solvedStates: [solvedstate, solvedstate, ...], string not null
    // moveFunc: function(state, move);
    // moves: {move: face0 | axis0}, face0 | axis0 = 4 + 4 bits
    function gSolver(solvedStates, doMove, moves, prunHash) {
        this.solvedStates = solvedStates;
        this.doMove = doMove;
        this.movesList = [];
        for (var move in moves) {
            this.movesList.push([move, moves[move]]);
        }
        this.prunHash = prunHash || identity;
        this.prunTable = {};
        this.toUpdateArr = null;
        this.prunTableSize = 0;
        this.prunDepth = -1;
        this.cost = 0;
    }

    _ = gSolver.prototype;

    _.updatePrun = function(targetDepth) {
        targetDepth = targetDepth === undefined ? this.prunDepth + 1 : targetDepth;
        for (var depth = this.prunDepth + 1; depth <= targetDepth; depth++) {
            var t = +new Date;
            if (depth < 1) {
                this.prevSize = 0;
                for (var i = 0; i < this.solvedStates.length; i++) {
                    var state = this.prunHash(this.solvedStates[i]);
                    if (!(state in this.prunTable)) {
                        this.prunTable[state] = depth;
                        this.prunTableSize++;
                    }
                }
            } else {
                this.updatePrunBFS(depth - 1);
            }
            if (this.cost == 0) {
                return;
            }
            this.prunDepth = depth;
            DEBUG && console.log(depth, this.prunTableSize - this.prevSize, +new Date - t);
            this.prevSize = this.prunTableSize;
        }
    };

    _.updatePrunBFS = function(fromDepth) {
        if (this.toUpdateArr == null) {
            this.toUpdateArr = [];
            for (var state in this.prunTable) {
                if (this.prunTable[state] != fromDepth) {
                    continue;
                }
                this.toUpdateArr.push(state);
            }
        }
        while (this.toUpdateArr.length != 0) {
            var state = this.toUpdateArr.pop();
            for (var moveIdx = 0; moveIdx < this.movesList.length; moveIdx++) {
                var newState = this.doMove(state, this.movesList[moveIdx][0]);
                if (!newState || newState in this.prunTable) {
                    continue;
                }
                this.prunTable[newState] = fromDepth + 1;
                this.prunTableSize++;
            }
            if (this.cost >= 0) {
                if (this.cost == 0) {
                    return;
                }
                this.cost--;
            }
        }
        this.toUpdateArr = null;
    };

    _.search = function(state, minl, MAXL) {
        this.sol = [];
        this.subOpt = false;
        this.state = state;
        this.visited = {};
        this.maxl = minl = minl || 0;
        return this.searchNext(MAXL);
    };

    _.searchNext = function(MAXL, cost) {
        MAXL = (MAXL + 1) || 99;
        this.prevSolStr = this.solArr ? this.solArr.join(',') : null;
        this.solArr = null;
        this.cost = cost || -1;
        for (; this.maxl < MAXL; this.maxl++) {
            this.updatePrun(Math.ceil(this.maxl / 2));
            if (this.cost == 0) {
                return null;
            }
            if (this.idaSearch(this.state, this.maxl, null, 0)) {
                break;
            }
        }
        return this.solArr;
    }

    _.getPruning = function(state) {
        var prun = this.prunTable[this.prunHash(state)];
        return prun === undefined ? this.prunDepth + 1 : prun;
    };

    _.idaSearch = function(state, maxl, lm, depth) {
        if (this.getPruning(state) > maxl) {
            return false;
        }
        if (maxl == 0) {
            if (this.solvedStates.indexOf(state) == -1) {
                return false;
            }
            var solArr = this.getSolArr();
            this.subOpt = true;
            if (solArr.join(',') == this.prevSolStr) {
                return false;
            }
            this.solArr = solArr;
            return true;
        }
        if (!this.subOpt) {
            if (state in this.visited && this.visited[state] < depth) {
                return false;
            }
            this.visited[state] = depth;
        }
        if (this.cost >= 0) {
            if (this.cost == 0) {
                return true;
            }
            this.cost--;
        }
        var lastMove = lm == null ? '' : this.movesList[lm][0];
        var lastAxisFace = lm == null ? -1 : this.movesList[lm][1];
        for (var moveIdx = this.sol[depth] || 0; moveIdx < this.movesList.length; moveIdx++) {
            var moveArgs = this.movesList[moveIdx];
            var axisface = moveArgs[1] ^ lastAxisFace;
            var move = moveArgs[0];
            if (axisface == 0 ||
                (axisface & 0xf) == 0 && move <= lastMove) {
                continue;
            }
            var newState = this.doMove(state, move);
            if (!newState || newState == state) {
                continue;
            }
            this.sol[depth] = moveIdx;
            if (this.idaSearch(newState, maxl - 1, moveIdx, depth + 1)) {
                return true;
            }
            this.sol.pop();
        }
        return false;
    };

    _.getSolArr = function() {
        var solArr = [];
        for (var i = 0; i < this.sol.length; i++) {
            solArr.push(this.movesList[this.sol[i]][0]);
        }
        return solArr;
    }

    var randGen = (function() {
        var rndFunc;
        var rndCnt;
        var seedStr; // '' + new Date().getTime();

        function random() {
            rndCnt++;
            // console.log(rndCnt);
            return rndFunc();
        }

        function getSeed() {
            return [rndCnt, seedStr];
        }

        function setSeed(_rndCnt, _seedStr) {
            if (_seedStr && (_seedStr != seedStr || rndCnt > _rndCnt)) {
                var seed = [];
                for (var i = 0; i < _seedStr.length; i++) {
                    seed[i] = _seedStr.charCodeAt(i);
                }
                rndFunc = new MersenneTwisterObject(seed[0], seed);
                rndCnt = 0;
                seedStr = _seedStr;
            }
            while (rndCnt < _rndCnt) {
                rndFunc();
                rndCnt++;
            }
        }

        // setSeed(0, '1576938267035');
        setSeed(0, '' + new Date().getTime());

        return {
            random: random,
            getSeed: getSeed,
            setSeed: setSeed
        };
    })();

    function rndEl(x) {
        return x[~~(randGen.random() * x.length)];
    }

    function rn(n) {
        return ~~(randGen.random() * n)
    }

    function rndPerm(n) {
        var arr = [];
        for (var i = 0; i < n; i++) {
            arr[i] = i;
        }
        for (var i = 0; i < n - 1; i++) {
            circle(arr, i, i + rn(n - i));
        }
        return arr;
    }

    function rndProb(plist) {
        var cum = 0;
        var curIdx = 0;
        for (var i = 0; i < plist.length; i++) {
            if (plist[i] == 0) {
                continue;
            }
            if (randGen.random() < plist[i] / (cum + plist[i])) {
                curIdx = i;
            }
            cum += plist[i];
        }
        return curIdx;
    }

    function time2str(unix, format) {
        if (!unix) {
            return 'N/A';
        }
        format = format || '%Y-%M-%D %h:%m:%s';
        var date = new Date(unix * 1000);
        return format
            .replace('%Y', date.getFullYear())
            .replace('%M', ('0' + (date.getMonth() + 1)).slice(-2))
            .replace('%D', ('0' + date.getDate()).slice(-2))
            .replace('%h', ('0' + date.getHours()).slice(-2))
            .replace('%m', ('0' + date.getMinutes()).slice(-2))
            .replace('%s', ('0' + date.getSeconds()).slice(-2));
    }

    var timeRe = /^\s*(\d+)-(\d+)-(\d+) (\d+):(\d+):(\d+)\s*$/;

    function str2time(val) {
        var m = timeRe.exec(val);
        if (!m) {
            return null;
        }
        var date = new Date(0);
        date.setFullYear(~~m[1]);
        date.setMonth(~~m[2] - 1);
        date.setDate(~~m[3]);
        date.setHours(~~m[4]);
        date.setMinutes(~~m[5]);
        date.setSeconds(~~m[6]);
        return ~~(date.getTime() / 1000);
    }

    function obj2str(val) {
        if (typeof val == 'string') {
            return val;
        }
        return JSON.stringify(val);
    }

    function str2obj(val) {
        if (typeof val != 'string') {
            return val;
        }
        return JSON.parse(val);
    }

    function valuedArray(len, val) {
        var ret = [];
        for (var i = 0; i < len; i++) {
            ret[i] = val;
        }
        return ret;
    }

    Math.TAU = Math.PI * 2;

    return {
        Cnk: Cnk,
        fact: fact,
        getPruning: getPruning,
        setNPerm: setNPerm,
        getNPerm: getNPerm,
        getNParity: getNParity,
        get8Perm: get8Perm,
        set8Perm: set8Perm,
        coord: coord,
        createMove: createMove,
        edgeMove: edgeMove,
        circle: circle,
        circleOri: circleOri,
        acycle: acycle,
        createPrun: createPrun,
        CubieCube: CubieCube,
        SOLVED_FACELET: "UUUUUUUUURRRRRRRRRFFFFFFFFFDDDDDDDDDLLLLLLLLLBBBBBBBBB",
        fillFacelet: fillFacelet,
        rn: rn,
        rndEl: rndEl,
        rndProb: rndProb,
        time2str: time2str,
        str2time: str2time,
        obj2str: obj2str,
        str2obj: str2obj,
        valuedArray: valuedArray,
        Solver: Solver,
        rndPerm: rndPerm,
        gSolver: gSolver,
        getSeed: randGen.getSeed,
        setSeed: randGen.setSeed
    };
})();

"use strict";

var scrMgr = (function(rn, rndEl) {

    function mega(turns, suffixes, length) {
        turns = turns || [[""]];
        suffixes = suffixes || [""];
        length = length || 0;
        var donemoves = 0;
        var lastaxis = -1;
        var s = [];
        var first, second;
        for (var i = 0; i < length; i++) {
            do {
                first = rn(turns.length);
                second = rn(turns[first].length);
                if (first != lastaxis) {
                    donemoves = 0;
                    lastaxis = first;
                }
            } while (((donemoves >> second) & 1) != 0);
            donemoves |= 1 << second;
            if (turns[first][second].constructor == Array) {
                s.push(rndEl(turns[first][second]) + rndEl(suffixes));
            } else {
                s.push(turns[first][second] + rndEl(suffixes));
            }
        }
        return s.join(' ');
    }

    /**
     *    {type: callback(type, length, state)}
     *    callback return: scramble string or undefined means delay
     */
    var scramblers = {
        "blank": function() {
            return "N/A";
        }
    };

    /**
     *    {type: [str1, str2, ..., strN]}
     */
    var filters = {};

    /**
     *    {type: [prob1, prob2, ..., probN]}
     */
    var probs = {};

    /**
     *    filter_and_probs: [[str1, ..., strN], [prob1, ..., probN]]
     */
    function regScrambler(type, callback, filter_and_probs) {
        for (var i = 0; i < type.length; i++) {
            scramblers[type[i]] = callback;
        }
        return regScrambler;
    }

    /**
     *    format string,
     *        ${args} => scramblers[scrType](scrType, scrArg)
     *        #{args} => mega(args)
     */
    function formatScramble(str) {
        var repfunc = function(match, p1) {
            if (match[0] == '$') {
                var args = [p1];
                if (p1[0] == '[') {
                    args = JSON.parse(p1);
                }
                return scramblers[args[0]].apply(this, args);
            } else if (match[0] == '#') {
                return mega.apply(this, JSON.parse('[' + p1 + ']'));
            } else {
                return '';
            }
        };
        var re1 = /[$#]\{([^\}]+)\}/g;
        return str.replace(re1, repfunc);
    }

    function rndState(filter, probs) {
        if (probs == undefined) {
            return undefined;
        }
        var ret = probs.slice();
        if (filter == undefined) {
            filter = ret;
        }
        for (var i = 0; i < filter.length; i++) {
            if (!filter[i]) {
                ret[i] = 0;
            }
        }
        return mathlib.rndProb(ret);
    }

    function fixCase(cases, probs) {
        return cases == undefined ? mathlib.rndProb(probs) : cases;
    }

    return {
        reg: regScrambler,
        scramblers: scramblers,
        filters: filters,
        probs: probs,
        mega: mega,
        formatScramble: formatScramble,
        rndState: rndState,
        fixCase: fixCase
    }
})(mathlib.rn, mathlib.rndEl);


var scramble = execMain(function(rn, rndEl) {
    var scramblers = scrMgr.scramblers;
    var filters = scrMgr.filters;
    var probs = scrMgr.probs;

    var alias = {
        '333oh': '333',
        '333ft': '333'
    };

    var scrFlt = "";

    function genScramble() {
        kernel.blur();
        sdiv.html('Scrambling...');
        typeExIn = (!type || /^(remote|input$)/.exec(type)) ? typeExIn : type;
        if (!isDisplayLast) {
            lasttype = type;
            lastscramble = scramble;
            lastlen = len;
        }
        isDisplayLast = false;
        if (lastscramble) {
            lastClick.addClass('click').unbind('click').click(procLastClick);
        }

        type = menu.getSelected();
        len = ~~scrLen.val();
        if (lasttype != type) {
            kernel.setProp('scrType', type);
        }
        scramble = "";
    }


    var type, scramble, len = 0;
    var lasttype, lastscramble, lastlen = 0;
    var typeExIn = '333';
    var isDisplayLast = false;

    function procLastClick() {
        isDisplayLast = true;
        sdiv.html(scrStd(lasttype, lastscramble, lastlen, true));
        lastClick.removeClass('click').unbind('click');
        if (lastscramble != undefined) {
            kernel.pushSignal('scrambleX', scrStd(lasttype, lastscramble, lastlen));
        }
    }

    function procNextClick() {
        if (isDisplayLast) {
            isDisplayLast = false;
            sdiv.html(scrStd(type, scramble, len, true));
            lastClick.addClass('click').unbind('click').click(procLastClick);
            kernel.pushSignal('scrambleX', scrStd(type, scramble, len));
        } else {
            genScramble();
        }
    }

    function procScrambleClick() {
        if (!scramble) {
            return;
        }
        var act = kernel.getProp('scrClk', 'n');
        if (act == 'c') {
            var succ = $.clipboardCopy(sdiv.text());
            if (succ) {
                logohint.push('scramble copied');
            }
        } else if (act == '+') {
            procNextClick();
        }
    }

    function scrStd(type, scramble, len, forDisplay) {
        scramble = scramble || '';
        len = len || 0;
        var m = /^\$T([a-zA-Z0-9]+)(-[0-9]+)?\$\s*(.*)$/.exec(scramble);
        if (m) {
            type = m[1];
            scramble = m[3];
            len = ~~m[2];
        }
        if (forDisplay) {
            var fontSize = kernel.getProp('scrASize') ? Math.max(0.25, Math.round(Math.pow(50 / Math.max(scramble.length, 10), 0.30) * 20) / 20) : 1;
            sdiv.css('font-size', fontSize + 'em');
            DEBUG && console.log('[scrFontSize]', fontSize);
            return scramble.replace(/~/g, '&nbsp;').replace(/\\n/g, '\n')
                .replace(/`([^']*)`/g, kernel.getProp('scrKeyM', false) ? '<u>$1</u>' : '$1');
        } else {
            return [type, scramble.replace(/~/g, '').replace(/\\n/g, '\n').replace(/`([^']*)`/g, '$1'), len];
        }
    }

    function doScrambleIt() {
        calcScramble();
        if (scramble) {
            scrambleOK();
        } else {
            sdiv.html("Scrambling... ");
        }
    }

    var enableCache = true;

    function setCacheEnable(enable) {
        enableCache = enable;
    }

    var cacheTid = 0;

    function genCachedScramble(args, detailType, isPredict) {
        if (!enableCache) {
            return;
        }
        if (csTimerWorker && csTimerWorker.getScramble) {
            cacheTid = cacheTid || csTimerWorker.getScramble(args, function(detailType, scramble) {
                DEBUG && console.log('[scrcache]', detailType + ' cached by csTimerWorker');
                saveCachedScramble(detailType, scramble);
            }.bind(undefined, detailType));
        } else if (!isPredict) {
            cacheTid = cacheTid || setTimeout(function(detailType, args) {
                var scrambler = scramblers[args[0]];
                saveCachedScramble(detailType, scrambler.apply(scrambler, args));
            }.bind(undefined, detailType, args), 500);
        }
    }

    function saveCachedScramble(detailType, scramble) {
        var cachedScr = JSON.parse(localStorage['cachedScr'] || null) || {};
        if ($.isArray(cachedScr)) {
            cachedScr = {};
        }
        cachedScr[detailType] = scramble;
        localStorage['cachedScr'] = JSON.stringify(cachedScr);
        cacheTid = 0;
    }

    function calcScramble() {
        if (!type) {
            return;
        }
        scramble = "";
        var realType = alias[type] || type;

        if (realType == 'input') {
            scramble = inputScrambleGen.next();
            return;
        } else {
            inputScrambleGen.clear();
        }

        if (realType.startsWith('remote')) {
            scramble = remoteScrambleGen.next(realType);
            return;
        } else {
            remoteScrambleGen.clear();
        }

        if (realType in scramblers) {
            var cachedScr = JSON.parse(localStorage['cachedScr'] || null) || {};
            var detailType = JSON.stringify([realType, len, scrFlt[1]]);
            if (enableCache && detailType in cachedScr) {
                scramble = cachedScr[detailType];
                delete cachedScr[detailType];
                localStorage['cachedScr'] = JSON.stringify(cachedScr);
            } else {
                scramble = scramblers[realType](realType, len, rndState(scrFlt[1], probs[realType]));
            }
            genCachedScramble([realType, len, rndState(scrFlt[1], probs[realType])], detailType);
            return;
        }

    }

    function scrambleOK(scrStr) {
        scramble = (scrStr || scramble).replace(/(\s*)$/, "");
        sdiv.html(scrStd(type, scramble, len, true));
        kernel.pushSignal('scramble', scrStd(type, scramble, len));
    }

    var remoteScrambleGen = (function() {
        var remoteScramble = [];
        var remoteURL = 'https://cstimer.net/testRemoteScramble.php';

        function next(type) {
            var ret = null;
            while (!ret && remoteScramble.length != 0) {
                ret = remoteScramble.shift();
            }
            if (ret) {
                return ret;
            }
            if (type == 'remoteComp') {
                if (!onlinecomp) {
                    remoteFail();
                }
                ret = onlinecomp.getScrambles();
                if (!parseInput(ret)) {
                    remoteFail();
                }
            } else if (type == 'remoteURL') {
                $.getJSON(remoteURL, function(ret) {
                    if (!parseInput(ret)) {
                        remoteFail();
                    }
                }).error(remoteFail);
            }
            return "";
        }

        function remoteFail() {
            kernel.setProp('scrType', typeExIn);
        }

        function clear() {
            remoteScramble = [];
        }

        function parseInput(ret) {
            if (!$.isArray(ret)) {
                return false;
            }
            remoteScramble = ret;
            return remoteScramble.length != 0;
        }

        return {
            next: next,
            clear: clear
        };
    })();

    var inputScrambleGen = (function() {

        var inputScramble = [];

        function next() {
            var ret = null;
            while (!ret && inputScramble.length != 0) {
                ret = inputScramble.shift();
            }
            if (ret) {
                return ret;
            }
            inputText.val("");
            kernel.showDialog([inputText, inputOK, inputCancel], 'input', SCRAMBLE_INPUT);
            return "";
        }

        function clear() {
            inputScramble = [];
        }

        function inputOK() {
            if (!parseInput(inputText.val())) {
                kernel.setProp('scrType', typeExIn);
            } else {
                doScrambleIt();
            }
        }

        function inputCancel() {
            kernel.setProp('scrType', typeExIn);
        }

        function parseInput(str) {
            if (str.match(/^\s*$/)) {
                return false;
            }
            inputScramble = [];
            var inputs = str.split('\n');
            for (var i = 0; i < inputs.length; i++) {
                var s = inputs[i];
                if (s.match(/^\s*$/) == null) {
                    inputScramble.push(s.replace(/^\d+[\.\),]\s*/, ''));
                }
            }
            return inputScramble.length != 0;
        }

        return {
            next: next,
            clear: clear
        };
    })();

    function loadScrOpts() {
        kernel.blur();
        var idx = menu.getSelIdx();
        var len = scrdata[idx[0]][1][idx[1]][2];
        scrLen.val(Math.abs(len));
        scrLen[0].disabled = len <= 0;
        var curType = menu.getSelected();
        scrFlt = JSON.parse(kernel.getProp('scrFlt', JSON.stringify([curType, filters[curType]])));
        scrOpt[0].disabled = scrLen[0].disabled && !(curType in filters);
        if (scrFlt[0] != curType) {
            scrFlt = [curType, filters[curType] && mathlib.valuedArray(filters[curType].length, 1)];
            kernel.setProp('scrFlt', JSON.stringify(scrFlt), 'session');
        }
    }

    function loadScrOptsAndGen() {
        loadScrOpts();
        genScramble();
    }

    function showScrOpt() {
        scrFltDiv.empty();
        var chkBoxList = [];
        var chkLabelList = [];
        var modified = false;
        if (type in filters) {
            var data = filters[type];
            var curData = data;
            if (scrFlt[0] == type) {
                curData = scrFlt[1] || data;
            }
            // console.log(scrFlt, curData);
            scrFltDiv.append('<br>', scrFltSelAll, scrFltSelNon, '<br><br>');
            var dataGroup = {};
            for (var i = 0; i < data.length; i++) {
                var spl = data[i].indexOf('-');
                if (spl == -1) {
                    dataGroup[data[i]] = [i];
                    continue;
                }
                var group = data[i].slice(0, spl);
                dataGroup[group] = dataGroup[group] || [];
                dataGroup[group].push(i);
            }
            for (var i = 0; i < data.length; i++) {
                var chkBox = $('<input type="checkbox">').val(i);
                if (curData[i]) {
                    chkBox[0].checked = true;
                }
                chkBoxList.push(chkBox);
                chkLabelList.push($('<label>').append(chkBox, data[i]));
            }

            var cntSel = function(g) {
                var cnt = 0;
                $.each(dataGroup[g], function(idx, val) {
                    cnt += chkBoxList[val][0].checked ? 1 : 0;
                });
                return cnt + '/' + dataGroup[g].length;
            };

            for (var g in dataGroup) {
                if (dataGroup[g].length == 1) {
                    scrFltDiv.append(chkLabelList[dataGroup[g][0]]);
                }
            }
            for (var g in dataGroup) {
                if (dataGroup[g].length == 1) {
                    continue;
                }
                scrFltDiv.append($('<div>').attr('data', g).append(
                    $('<span>').html(g + ' ' + cntSel(g)), ' | ',
                    $('<span class="click">').html('All').click(function() {
                        var g = $(this).parent().attr('data');
                        $.each(dataGroup[g], function(idx, val) {
                            chkBoxList[val][0].checked = true;
                        });
                        $(this).parent().children().first().html(g + ' ' + cntSel(g));
                    }), ' | ',
                    $('<span class="click">').html('None').click(function() {
                        var g = $(this).parent().attr('data');
                        $.each(dataGroup[g], function(idx, val) {
                            chkBoxList[val][0].checked = false;
                        });
                        $(this).parent().children().first().html(g + ' ' + cntSel(g));
                    }), ' | ',
                    $('<span class="click">[+]</span>').click(function() {
                        $(this).next().toggle();
                    }),
                    $('<div>').append($.map(dataGroup[g], function(val) {
                        chkBoxList[val].change(function() {
                            var g = $(this).parent().parent().parent().attr('data');
                            $(this).parent().parent().parent().children().first().html(g + ' ' + cntSel(g));
                        });
                        return chkLabelList[val];
                    })).hide())
                );
            }

            scrFltSelAll.unbind('click').click(function() {
                for (var i = 0; i < chkBoxList.length; i++) {
                    if (!chkBoxList[i][0].checked) {
                        chkBoxList[i][0].checked = true;
                    }
                    chkBoxList[i].change();
                }
            });
            scrFltSelNon.unbind('click').click(function() {
                for (var i = 0; i < chkBoxList.length; i++) {
                    if (chkBoxList[i][0].checked) {
                        chkBoxList[i][0].checked = false;
                    }
                    chkBoxList[i].change();
                }
            });
        }

        function procDialog() {
            if (type in filters) {
                var data = mathlib.valuedArray(filters[type].length, 1);
                var hasVal = false;
                for (var i = 0; i < chkBoxList.length; i++) {
                    if (!chkBoxList[i][0].checked) {
                        data[i] = 0;
                    } else {
                        hasVal = true;
                    }
                }
                if (!hasVal) {
                    alert('Should Select At Least One Case');
                } else {
                    scrFlt = [type, data];
                    var scrFltStr = JSON.stringify(scrFlt);
                    if (kernel.getProp('scrFlt') != scrFltStr) {
                        modified = true;
                        kernel.setProp('scrFlt', scrFltStr);
                    }
                }
                if (modified) {
                    genScramble();
                }
            }
        }
        kernel.showDialog([scrOptDiv, procDialog, null, procDialog], 'scropt', 'Scramble Options');
    }

    var isEn = false;

    function procSignal(signal, value) {
        if (signal == 'time') {
            if (isEn) {
                genScramble();
            } else {
                sdiv.empty();
                kernel.pushSignal('scramble', ['-', '', 0]);
            }
        } else if (signal == 'property') {
            if (value[0] == 'scrSize') {
                ssdiv.css('font-size', value[1] / 7 + 'em');
            } else if (value[0] == 'scrMono') {
                div.css('font-family', value[1] ? 'SimHei, Monospace' : 'Arial');
            } else if (value[0] == 'scrType') {
                if (value[1] != menu.getSelected()) {
                    loadType(value[1]);
                }
            } else if (value[0] == 'scrLim') {
                if (value[1]) {
                    ssdiv.addClass('limit');
                } else {
                    ssdiv.removeClass('limit');
                }
            } else if (value[0] == 'scrAlign') {
                if (value[1] == 'c') {
                    div.css('text-align', 'center');
                } else if (value[1] == 'l') {
                    div.css('text-align', 'left');
                } else if (value[1] == 'r') {
                    div.css('text-align', 'right');
                }
            } else if (value[0] == 'scrFast') {
                alias['444wca'] = value[1] ? '444m' : '444wca';
                if (type == '444wca') {
                    genScramble();
                }
            } else if (value[0] == 'scrKeyM') {
                sdiv.html(isDisplayLast ? scrStd(lasttype, lastscramble || '', lastlen || 0, true) : scrStd(type, scramble || '', len, true));
            } else if (value[0] == 'scrHide') {
                if (value[1]) {
                    title.hide();
                } else {
                    title.show();
                }
            }
        } else if (signal == 'button' && value[0] == 'scramble') {
            isEn = value[1];
            if (isEn && sdiv.html() == '') {
                genScramble();
            }
        } else if (signal == 'ctrl' && value[0] == 'scramble') {
            if (value[1] == 'last') {
                procLastClick();
            } else if (value[1] == 'next') {
                procNextClick();
            }
        }
    }

    function procOnType(type, func) {
        for (var i = 0; i < scrdata.length; i++) {
            for (var j = 0; j < scrdata[i][1].length; j++) {
                if (scrdata[i][1][j][1] == type) {
                    func(i, j);
                    return;
                }
            }
        }
    }

    function loadType(type) {
        menu.loadVal(type);
        loadScrOptsAndGen();
    }

    function getTypeName(type) {
        var name = '';
        procOnType(type, function(i, j) {
            name = scrdata[i][0] + '>' + scrdata[i][1][j][0];
        });
        return name;
    }

    function getTypeIdx(type) {
        var idx = 1e300;
        procOnType(type, function(i, j) {
            idx = i * 100 + j;
        });
        return idx;
    }

    var scrambleGenerator = (function() {
       

        function generate() {
            var n_scramble = ~~scrNum.val();
            var scrambles = "";
            var scramble_copy = scramble;
            var pre = prefix.val();
            for (var i = 0; i < n_scramble; i++) {
                calcScramble();
                scrambles += pre.replace('1', i + 1) + scramble + "\n";
            }
            // console.log(scrambles);
            scramble = scramble_copy;
            output.text(scrambles);
            output.select();
        }

        return function(fdiv) {
            if (!fdiv) {
                return;
            }
            fdiv.empty().append(tdiv.width(div.width() / 2));
            prefix.unbind("change").change(kernel.blur);
            button.unbind("click").click(generate);
        }
    })();

    var rndState = scrMgr.rndState;

    return {
        getTypeName: getTypeName,
        getTypeIdx: getTypeIdx,
        scrStd: scrStd,
        setCacheEnable: setCacheEnable
    }
}, [mathlib.rn, mathlib.rndEl]);

"use strict";

var min2phase = (function() {
    var USE_TWIST_FLIP_PRUN = true;
    var PARTIAL_INIT_LEVEL = 2;

    var MAX_PRE_MOVES = 20;
    var TRY_INVERSE = true;
    var TRY_THREE_AXES = true;

    var USE_COMBP_PRUN = true; //USE_TWIST_FLIP_PRUN;
    var USE_CONJ_PRUN = USE_TWIST_FLIP_PRUN;
    var MIN_P1LENGTH_PRE = 7;
    var MAX_DEPTH2 = 13;

    var INVERSE_SOLUTION = 0x2;

    function Search() {
        this.move = [];
        this.moveSol = [];

        this.nodeUD = [];

        this.valid1 = 0;
        this.allowShorter = false;
        this.cc = new CubieCube();
        this.urfCubieCube = [];
        this.urfCoordCube = [];
        this.phase1Cubie = [];

        this.preMoveCubes = [];
        this.preMoves = [];
        this.preMoveLen = 0;
        this.maxPreMoves = 0;

        this.isRec = false;
        for (var i = 0; i < 21; i++) {
            this.nodeUD[i] = new CoordCube();
            this.phase1Cubie[i] = new CubieCube();
        }
        for (var i = 0; i < 6; i++) {
            this.urfCubieCube[i] = new CubieCube();
            this.urfCoordCube[i] = new CoordCube();
        }
        for (var i = 0; i < MAX_PRE_MOVES; i++) {
            this.preMoveCubes[i + 1] = new CubieCube();
        }
    }

    var Ux1 = 0;
    var Ux2 = 1;
    var Ux3 = 2;
    var Rx1 = 3;
    var Rx2 = 4;
    var Rx3 = 5;
    var Fx1 = 6;
    var Fx2 = 7;
    var Fx3 = 8;
    var Dx1 = 9;
    var Dx2 = 10;
    var Dx3 = 11;
    var Lx1 = 12;
    var Lx2 = 13;
    var Lx3 = 14;
    var Bx1 = 15;
    var Bx2 = 16;
    var Bx3 = 17;

    var N_MOVES = 18;
    var N_MOVES2 = 10;
    var N_FLIP = 2048;
    var N_FLIP_SYM = 336;
    var N_TWIST = 2187;
    var N_TWIST_SYM = 324;
    var N_PERM = 40320;
    var N_PERM_SYM = 2768;
    var N_MPERM = 24;
    var N_SLICE = 495;
    var N_COMB = USE_COMBP_PRUN ? 140 : 70;
    var P2_PARITY_MOVE = USE_COMBP_PRUN ? 0xA5 : 0;

    var SYM_E2C_MAGIC = 0x00DDDD00;
    var Cnk = [];
    var fact = [1];
    var move2str = [
        "U ", "U2", "U'", "R ", "R2", "R'", "F ", "F2", "F'",
        "D ", "D2", "D'", "L ", "L2", "L'", "B ", "B2", "B'"
    ];
    var ud2std = [Ux1, Ux2, Ux3, Rx2, Fx2, Dx1, Dx2, Dx3, Lx2, Bx2, Rx1, Rx3, Fx1, Fx3, Lx1, Lx3, Bx1, Bx3];
    var std2ud = [];
    var ckmv2bit = [];
    var urfMove = [
        [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17],
        [6, 7, 8, 0, 1, 2, 3, 4, 5, 15, 16, 17, 9, 10, 11, 12, 13, 14],
        [3, 4, 5, 6, 7, 8, 0, 1, 2, 12, 13, 14, 15, 16, 17, 9, 10, 11],
        [2, 1, 0, 5, 4, 3, 8, 7, 6, 11, 10, 9, 14, 13, 12, 17, 16, 15],
        [8, 7, 6, 2, 1, 0, 5, 4, 3, 17, 16, 15, 11, 10, 9, 14, 13, 12],
        [5, 4, 3, 8, 7, 6, 2, 1, 0, 14, 13, 12, 17, 16, 15, 11, 10, 9]
    ];

    { // init util
        for (var i = 0; i < 18; i++) {
            std2ud[ud2std[i]] = i;
        }
        for (var i = 0; i < 10; i++) {
            var ix = ~~(ud2std[i] / 3);
            ckmv2bit[i] = 0;
            for (var j = 0; j < 10; j++) {
                var jx = ~~(ud2std[j] / 3);
                ckmv2bit[i] |= ((ix == jx) || ((ix % 3 == jx % 3) && (ix >= jx)) ? 1 : 0) << j;
            }
        }
        ckmv2bit[10] = 0;
        for (var i = 0; i < 13; i++) {
            Cnk[i] = [];
            fact[i + 1] = fact[i] * (i + 1);
            Cnk[i][0] = Cnk[i][i] = 1;
            for (var j = 1; j < 13; j++) {
                Cnk[i][j] = j <= i ? Cnk[i - 1][j - 1] + Cnk[i - 1][j] : 0;
            }
        }
    }

    function setVal(val0, val, isEdge) {
        return isEdge ? (val << 1 | val0 & 1) : (val | val0 & 0xf8);
    }

    function getVal(val0, isEdge) {
        return isEdge ? val0 >> 1 : val0 & 7;
    }

    function setPruning(table, index, value) {
        table[index >> 3] ^= value << (index << 2); // index << 2 <=> (index & 7) << 2
    }

    function getPruning(table, index) {
        return table[index >> 3] >> (index << 2) & 0xf; // index << 2 <=> (index & 7) << 2
    }

    function getPruningMax(maxValue, table, index) {
        return Math.min(maxValue, table[index >> 3] >> (index << 2) & 0xf);
    }

    function hasZero(val) {
        return ((val - 0x11111111) & ~val & 0x88888888) != 0;
    }

    function ESym2CSym(idx) {
        return idx ^ (SYM_E2C_MAGIC >> ((idx & 0xf) << 1) & 3);
    }

    function getPermSymInv(idx, sym, isCorner) {
        var idxi = PermInvEdgeSym[idx];
        if (isCorner) {
            idxi = ESym2CSym(idxi);
        }
        return idxi & 0xfff0 | SymMult[idxi & 0xf][sym];
    }

    function CubieCube() {
        this.ca = [0, 1, 2, 3, 4, 5, 6, 7];
        this.ea = [0, 2, 4, 6, 8, 10, 12, 14, 16, 18, 20, 22];
    }

    function setNPerm(arr, idx, n, isEdge) {
        n--;
        var val = 0x76543210;
        for (var i = 0; i < n; ++i) {
            var p = fact[n - i];
            var v = ~~(idx / p);
            idx %= p;
            v <<= 2;
            arr[i] = setVal(arr[i], val >> v & 0xf, isEdge);
            var m = (1 << v) - 1;
            val = (val & m) + (val >> 4 & ~m);
        }
        arr[n] = setVal(arr[n], val & 0xf, isEdge);
    }

    function getNPerm(arr, n, isEdge) {
        var idx = 0,
            val = 0x76543210;
        for (var i = 0; i < n - 1; ++i) {
            var v = getVal(arr[i], isEdge) << 2;
            idx = (n - i) * idx + (val >> v & 0xf);
            val -= 0x11111110 << v;
        }
        return idx;
    }

    function setNPermFull(arr, idx, n, isEdge) {
        arr[n - 1] = setVal(arr[n - 1], 0, isEdge);;
        for (var i = n - 2; i >= 0; --i) {
            arr[i] = setVal(arr[i], idx % (n - i), isEdge);
            idx = ~~(idx / (n - i));
            for (var j = i + 1; j < n; ++j) {
                if (getVal(arr[j], isEdge) >= getVal(arr[i], isEdge)) {
                    arr[j] = setVal(arr[j], getVal(arr[j], isEdge) + 1, isEdge);
                }
            }
        }
    }

    function getNPermFull(arr, n, isEdge) {
        var idx = 0;
        for (var i = 0; i < n; ++i) {
            idx *= n - i;
            for (var j = i + 1; j < n; ++j) {
                if (getVal(arr[j], isEdge) < getVal(arr[i], isEdge)) {
                    ++idx;
                }
            }
        }
        return idx;
    }

    function getComb(arr, mask, isEdge) {
        var end = arr.length - 1;
        var idxC = 0,
            r = 4;
        for (var i = end; i >= 0; i--) {
            var perm = getVal(arr[i], isEdge);
            if ((perm & 0xc) == mask) {
                idxC += Cnk[i][r--];
            }
        }
        return idxC;
    }

    function setComb(arr, idxC, mask, isEdge) {
        var end = arr.length - 1;
        var r = 4,
            fill = end;
        for (var i = end; i >= 0; i--) {
            if (idxC >= Cnk[i][r]) {
                idxC -= Cnk[i][r--];
                arr[i] = setVal(arr[i], r | mask, isEdge);
            } else {
                if ((fill & 0xc) == mask) {
                    fill -= 4;
                }
                arr[i] = setVal(arr[i], fill--, isEdge);
            }
        }
    }

    function getNParity(idx, n) {
        var p = 0;
        for (var i = n - 2; i >= 0; i--) {
            p ^= idx % (n - i);
            idx = ~~(idx / (n - i));
        }
        return p & 1;
    }
    CubieCube.EdgeMult = function(a, b, prod) {
        for (var ed = 0; ed < 12; ed++) {
            prod.ea[ed] = a.ea[b.ea[ed] >> 1] ^ (b.ea[ed] & 1);
        }
    }
    CubieCube.CornMult = function(a, b, prod) {
        for (var corn = 0; corn < 8; corn++) {
            var ori = ((a.ca[b.ca[corn] & 7] >> 3) + (b.ca[corn] >> 3)) % 3;
            prod.ca[corn] = a.ca[b.ca[corn] & 7] & 7 | ori << 3;
        }
    }
    CubieCube.CornMultFull = function(a, b, prod) {
        for (var corn = 0; corn < 8; corn++) {
            var oriA = a.ca[b.ca[corn] & 7] >> 3;
            var oriB = b.ca[corn] >> 3;
            var ori = oriA + ((oriA < 3) ? oriB : 6 - oriB);
            ori = ori % 3 + ((oriA < 3) == (oriB < 3) ? 0 : 3);
            prod.ca[corn] = a.ca[b.ca[corn] & 7] & 7 | ori << 3;
        }
    }
    CubieCube.CornConjugate = function(a, idx, b) {
        var sinv = SymCube[SymMultInv[0][idx]];
        var s = SymCube[idx];
        for (var corn = 0; corn < 8; corn++) {
            var oriA = sinv.ca[a.ca[s.ca[corn] & 7] & 7] >> 3;
            var oriB = a.ca[s.ca[corn] & 7] >> 3;
            var ori = (oriA < 3) ? oriB : (3 - oriB) % 3;
            b.ca[corn] = sinv.ca[a.ca[s.ca[corn] & 7] & 7] & 7 | ori << 3;
        }
    }
    CubieCube.EdgeConjugate = function(a, idx, b) {
        var sinv = SymCube[SymMultInv[0][idx]];
        var s = SymCube[idx];
        for (var ed = 0; ed < 12; ed++) {
            b.ea[ed] = sinv.ea[a.ea[s.ea[ed] >> 1] >> 1] ^ (a.ea[s.ea[ed] >> 1] & 1) ^ (s.ea[ed] & 1);
        }
    }
    CubieCube.prototype.init = function(ca, ea) {
        this.ca = ca.slice();
        this.ea = ea.slice();
        return this;
    }
    CubieCube.prototype.initCoord = function(cperm, twist, eperm, flip) {
        setNPerm(this.ca, cperm, 8, false);
        this.setTwist(twist);
        setNPermFull(this.ea, eperm, 12, true);
        this.setFlip(flip);
        return this;
    }
    CubieCube.prototype.isEqual = function(c) {
        for (var i = 0; i < 8; i++) {
            if (this.ca[i] != c.ca[i]) {
                return false;
            }
        }
        for (var i = 0; i < 12; i++) {
            if (this.ea[i] != c.ea[i]) {
                return false;
            }
        }
        return true;
    }
    CubieCube.prototype.setFlip = function(idx) {
        var parity = 0,
            val;
        for (var i = 10; i >= 0; i--, idx >>= 1) {
            parity ^= (val = idx & 1);
            this.ea[i] = this.ea[i] & 0xfe | val;
        }
        this.ea[11] = this.ea[11] & 0xfe | parity;
    }
    CubieCube.prototype.getFlip = function() {
        var idx = 0;
        for (var i = 0; i < 11; i++) {
            idx = idx << 1 | this.ea[i] & 1;
        }
        return idx;
    }
    CubieCube.prototype.getFlipSym = function() {
        return FlipR2S[this.getFlip()];
    }
    CubieCube.prototype.setTwist = function(idx) {
        var twst = 15,
            val;
        for (var i = 6; i >= 0; i--, idx = ~~(idx / 3)) {
            twst -= (val = idx % 3);
            this.ca[i] = this.ca[i] & 0x7 | val << 3;
        }
        this.ca[7] = this.ca[7] & 0x7 | (twst % 3) << 3;
    }
    CubieCube.prototype.getTwist = function() {
        var idx = 0;
        for (var i = 0; i < 7; i++) {
            idx += (idx << 1) + (this.ca[i] >> 3);
        }
        return idx;
    }
    CubieCube.prototype.getTwistSym = function() {
        return TwistR2S[this.getTwist()];

    }
    CubieCube.prototype.setCPerm = function(idx) {
        setNPerm(this.ca, idx, 8, false);
    }
    CubieCube.prototype.getCPerm = function() {
        return getNPerm(this.ca, 8, false);
    }
    CubieCube.prototype.getCPermSym = function() {
        return ESym2CSym(EPermR2S[getNPerm(this.ca, 8, false)]);
    }
    CubieCube.prototype.setEPerm = function(idx) {
        setNPerm(this.ea, idx, 8, true);
    }
    CubieCube.prototype.getEPerm = function() {
        return getNPerm(this.ea, 8, true);
    }
    CubieCube.prototype.getEPermSym = function() {
        return EPermR2S[getNPerm(this.ea, 8, true)];
    }
    CubieCube.prototype.getUDSlice = function() {
        return 494 - getComb(this.ea, 8, true);
    }
    CubieCube.prototype.setUDSlice = function(idx) {
        setComb(this.ea, 494 - idx, 8, true);
    }
    CubieCube.prototype.getMPerm = function() {
        return getNPermFull(this.ea, 12, true) % 24;
    }
    CubieCube.prototype.setMPerm = function(idx) {
        setNPermFull(this.ea, idx, 12, true);
    }
    CubieCube.prototype.getCComb = function() {
        return getComb(this.ca, 0, false);
    }
    CubieCube.prototype.setCComb = function(idx) {
        setComb(this.ca, idx, 0, false);
    }
    CubieCube.prototype.URFConjugate = function() {
        var temps = new CubieCube();
        CubieCube.CornMult(CubieCube.urf2, this, temps);
        CubieCube.CornMult(temps, CubieCube.urf1, this);
        CubieCube.EdgeMult(CubieCube.urf2, this, temps);
        CubieCube.EdgeMult(temps, CubieCube.urf1, this);
    }
    var cornerFacelet = [
        [8, 9, 20],
        [6, 18, 38],
        [0, 36, 47],
        [2, 45, 11],
        [29, 26, 15],
        [27, 44, 24],
        [33, 53, 42],
        [35, 17, 51]
    ];
    var edgeFacelet = [
        [5, 10],
        [7, 19],
        [3, 37],
        [1, 46],
        [32, 16],
        [28, 25],
        [30, 43],
        [34, 52],
        [23, 12],
        [21, 41],
        [50, 39],
        [48, 14]
    ];
    CubieCube.prototype.toFaceCube = function(cFacelet, eFacelet) {
        cFacelet = cFacelet || cornerFacelet;
        eFacelet = eFacelet || edgeFacelet;
        var ts = "URFDLB";
        var f = [];
        for (var i = 0; i < 54; i++) {
            f[i] = ts[~~(i / 9)];
        }
        for (var c = 0; c < 8; c++) {
            var j = this.ca[c] & 0x7; // cornercubie with index j is at
            var ori = this.ca[c] >> 3; // Orientation of this cubie
            for (var n = 0; n < 3; n++)
                f[cFacelet[c][(n + ori) % 3]] = ts[~~(cFacelet[j][n] / 9)];
        }
        for (var e = 0; e < 12; e++) {
            var j = this.ea[e] >> 1; // edgecubie with index j is at edgeposition
            var ori = this.ea[e] & 1; // Orientation of this cubie
            for (var n = 0; n < 2; n++)
                f[eFacelet[e][(n + ori) % 2]] = ts[~~(eFacelet[j][n] / 9)];
        }
        return f.join("");
    }
    CubieCube.prototype.invFrom = function(cc) {
        for (var edge = 0; edge < 12; edge++) {
            this.ea[cc.ea[edge] >> 1] = edge << 1 | cc.ea[edge] & 1;
        }
        for (var corn = 0; corn < 8; corn++) {
            this.ca[cc.ca[corn] & 0x7] = corn | 0x20 >> (cc.ca[corn] >> 3) & 0x18;
        }
        return this;
    }
    CubieCube.prototype.fromFacelet = function(facelet, cFacelet, eFacelet) {
        cFacelet = cFacelet || cornerFacelet;
        eFacelet = eFacelet || edgeFacelet;
        var count = 0;
        var f = [];
        var centers = facelet[4] + facelet[13] + facelet[22] + facelet[31] + facelet[40] + facelet[49];
        for (var i = 0; i < 54; ++i) {
            f[i] = centers.indexOf(facelet[i]);
            if (f[i] == -1) {
                return -1;
            }
            count += 1 << (f[i] << 2);
        }
        if (count != 0x999999) {
            return -1;
        }
        var col1, col2, i, j, ori;
        for (i = 0; i < 8; ++i) {
            for (ori = 0; ori < 3; ++ori)
                if (f[cFacelet[i][ori]] == 0 || f[cFacelet[i][ori]] == 3)
                    break;
            col1 = f[cFacelet[i][(ori + 1) % 3]];
            col2 = f[cFacelet[i][(ori + 2) % 3]];
            for (j = 0; j < 8; ++j) {
                if (col1 == ~~(cFacelet[j][1] / 9) && col2 == ~~(cFacelet[j][2] / 9)) {
                    this.ca[i] = j | ori % 3 << 3;
                    break;
                }
            }
        }
        for (i = 0; i < 12; ++i) {
            for (j = 0; j < 12; ++j) {
                if (f[eFacelet[i][0]] == ~~(eFacelet[j][0] / 9) && f[eFacelet[i][1]] == ~~(eFacelet[j][1] / 9)) {
                    this.ea[i] = j << 1;
                    break;
                }
                if (f[eFacelet[i][0]] == ~~(eFacelet[j][1] / 9) && f[eFacelet[i][1]] == ~~(eFacelet[j][0] / 9)) {
                    this.ea[i] = j << 1 | 1;
                    break;
                }
            }
        }
    }

    function CoordCube() {
        this.twist = 0;
        this.tsym = 0;
        this.flip = 0;
        this.fsym = 0;
        this.slice = 0;
        this.prun = 0;
        this.twistc = 0;
        this.flipc = 0;
    }
    CoordCube.prototype.set = function(node) {
        this.twist = node.twist;
        this.tsym = node.tsym;
        this.flip = node.flip;
        this.fsym = node.fsym;
        this.slice = node.slice;
        this.prun = node.prun;
        if (USE_CONJ_PRUN) {
            this.twistc = node.twistc;
            this.flipc = node.flipc;
        }
    }
    CoordCube.prototype.calcPruning = function(isPhase1) {
        this.prun = Math.max(
            Math.max(
                getPruningMax(UDSliceTwistPrunMax, UDSliceTwistPrun,
                    this.twist * N_SLICE + UDSliceConj[this.slice][this.tsym]),
                getPruningMax(UDSliceFlipPrunMax, UDSliceFlipPrun,
                    this.flip * N_SLICE + UDSliceConj[this.slice][this.fsym])),
            Math.max(
                USE_CONJ_PRUN ? getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
                    (this.twistc >> 3) << 11 | FlipS2RF[this.flipc ^ (this.twistc & 7)]) : 0,
                USE_TWIST_FLIP_PRUN ? getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
                    this.twist << 11 | FlipS2RF[this.flip << 3 | (this.fsym ^ this.tsym)]) : 0));
    }
    CoordCube.prototype.setWithPrun = function(cc, depth) {
        this.twist = cc.getTwistSym();
        this.flip = cc.getFlipSym();
        this.tsym = this.twist & 7;
        this.twist = this.twist >> 3;
        this.prun = USE_TWIST_FLIP_PRUN ? getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
            this.twist << 11 | FlipS2RF[this.flip ^ this.tsym]) : 0;
        if (this.prun > depth) {
            return false;
        }
        this.fsym = this.flip & 7;
        this.flip = this.flip >> 3;
        this.slice = cc.getUDSlice();
        this.prun = Math.max(this.prun, Math.max(
            getPruningMax(UDSliceTwistPrunMax, UDSliceTwistPrun,
                this.twist * N_SLICE + UDSliceConj[this.slice][this.tsym]),
            getPruningMax(UDSliceFlipPrunMax, UDSliceFlipPrun,
                this.flip * N_SLICE + UDSliceConj[this.slice][this.fsym])));
        if (this.prun > depth) {
            return false;
        }
        if (USE_CONJ_PRUN) {
            var pc = new CubieCube();
            CubieCube.CornConjugate(cc, 1, pc);
            CubieCube.EdgeConjugate(cc, 1, pc);
            this.twistc = pc.getTwistSym();
            this.flipc = pc.getFlipSym();
            this.prun = Math.max(this.prun,
                getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
                    (this.twistc >> 3) << 11 | FlipS2RF[this.flipc ^ (this.twistc & 7)]));
        }
        return this.prun <= depth;
    }
    CoordCube.prototype.doMovePrun = function(cc, m, isPhase1) {
        this.slice = UDSliceMove[cc.slice][m];
        this.flip = FlipMove[cc.flip][Sym8Move[m << 3 | cc.fsym]];
        this.fsym = (this.flip & 7) ^ cc.fsym;
        this.flip >>= 3;
        this.twist = TwistMove[cc.twist][Sym8Move[m << 3 | cc.tsym]];
        this.tsym = (this.twist & 7) ^ cc.tsym;
        this.twist >>= 3;
        this.prun = Math.max(
            Math.max(
                getPruningMax(UDSliceTwistPrunMax, UDSliceTwistPrun,
                    this.twist * N_SLICE + UDSliceConj[this.slice][this.tsym]),
                getPruningMax(UDSliceFlipPrunMax, UDSliceFlipPrun,
                    this.flip * N_SLICE + UDSliceConj[this.slice][this.fsym])),
            USE_TWIST_FLIP_PRUN ? getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
                this.twist << 11 | FlipS2RF[this.flip << 3 | (this.fsym ^ this.tsym)]) : 0);
        return this.prun;
    }
    CoordCube.prototype.doMovePrunConj = function(cc, m) {
        m = SymMove[3][m];
        this.flipc = FlipMove[cc.flipc >> 3][Sym8Move[m << 3 | cc.flipc & 7]] ^ (cc.flipc & 7);
        this.twistc = TwistMove[cc.twistc >> 3][Sym8Move[m << 3 | cc.twistc & 7]] ^ (cc.twistc & 7);
        return getPruningMax(TwistFlipPrunMax, TwistFlipPrun,
            (this.twistc >> 3) << 11 | FlipS2RF[this.flipc ^ (this.twistc & 7)]);
    }
    Search.prototype.solution = function(facelets, maxDepth, probeMax, probeMin, verbose) {
        initPrunTables();
        var check = this.verify(facelets);
        if (check != 0) {
            return "Error " + Math.abs(check);
        }
        if (maxDepth === undefined) {
            maxDepth = 21;
        }
        if (probeMax === undefined) {
            probeMax = 1e9;
        }
        if (probeMin === undefined) {
            probeMin = 0;
        }
        if (verbose === undefined) {
            verbose = 0;
        }
        this.sol = maxDepth + 1;
        this.probe = 0;
        this.probeMax = probeMax;
        this.probeMin = Math.min(probeMin, probeMax);
        this.verbose = verbose;
        this.moveSol = null;
        this.isRec = false;
        this.initSearch();
        return this.search();
    }

    Search.prototype.initSearch = function() {
        this.conjMask = (TRY_INVERSE ? 0 : 0x38) | (TRY_THREE_AXES ? 0 : 0x36);
        this.maxPreMoves = this.conjMask > 7 ? 0 : MAX_PRE_MOVES;

        for (var i = 0; i < 6; i++) {
            this.urfCubieCube[i].init(this.cc.ca, this.cc.ea);
            this.urfCoordCube[i].setWithPrun(this.urfCubieCube[i], 20);
            this.cc.URFConjugate();
            if (i % 3 == 2) {
                var tmp = new CubieCube().invFrom(this.cc);
                this.cc.init(tmp.ca, tmp.ea);
            }
        }
    }

    Search.prototype.next = function(probeMax, probeMin, verbose) {
        this.probe = 0;
        this.probeMax = probeMax;
        this.probeMin = Math.min(probeMin, probeMax);
        this.moveSol = null;
        this.isRec = true;
        this.verbose = verbose;
        return search();
    }

    Search.prototype.verify = function(facelets) {
        if (this.cc.fromFacelet(facelets) == -1) {
            return -1;
        }
        var sum = 0;
        var edgeMask = 0;
        for (var e = 0; e < 12; e++) {
            edgeMask |= 1 << (this.cc.ea[e] >> 1);
            sum ^= this.cc.ea[e] & 1;
        }
        if (edgeMask != 0xfff) {
            return -2; // missing edges
        }
        if (sum != 0) {
            return -3;
        }
        var cornMask = 0;
        sum = 0;
        for (var c = 0; c < 8; c++) {
            cornMask |= 1 << (this.cc.ca[c] & 7);
            sum += this.cc.ca[c] >> 3;
        }
        if (cornMask != 0xff) {
            return -4; // missing corners
        }
        if (sum % 3 != 0) {
            return -5; // twisted corner
        }
        if ((getNParity(getNPermFull(this.cc.ea, 12, true), 12) ^ getNParity(this.cc.getCPerm(), 8)) != 0) {
            return -6; // parity error
        }
        return 0; // cube ok
    }

    Search.prototype.phase1PreMoves = function(maxl, lm, cc) {
        this.preMoveLen = this.maxPreMoves - maxl;
        if (this.isRec ? (this.depth1 == this.length1 - this.preMoveLen) :
            (this.preMoveLen == 0 || (0x36FB7 >> lm & 1) == 0)) {
            this.depth1 = this.length1 - this.preMoveLen;
            this.phase1Cubie[0].init(cc.ca, cc.ea) /* = cc*/ ;
            this.allowShorter = this.depth1 == MIN_P1LENGTH_PRE && this.preMoveLen != 0;

            if (this.nodeUD[this.depth1 + 1].setWithPrun(cc, this.depth1) &&
                this.phase1(this.nodeUD[this.depth1 + 1], this.depth1, -1) == 0) {
                return 0;
            }
        }

        if (maxl == 0 || this.preMoveLen + MIN_P1LENGTH_PRE >= this.length1) {
            return 1;
        }

        var skipMoves = 0;
        if (maxl == 1 || this.preMoveLen + 1 + MIN_P1LENGTH_PRE >= this.length1) { //last pre move
            skipMoves |= 0x36FB7; // 11 0110 1111 1011 0111
        }

        lm = ~~(lm / 3) * 3;
        for (var m = 0; m < 18; m++) {
            if (m == lm || m == lm - 9 || m == lm + 9) {
                m += 2;
                continue;
            }
            if (this.isRec && m != this.preMoves[this.maxPreMoves - maxl] || (skipMoves & 1 << m) != 0) {
                continue;
            }
            CubieCube.CornMult(moveCube[m], cc, this.preMoveCubes[maxl]);
            CubieCube.EdgeMult(moveCube[m], cc, this.preMoveCubes[maxl]);
            this.preMoves[this.maxPreMoves - maxl] = m;
            var ret = this.phase1PreMoves(maxl - 1, m, this.preMoveCubes[maxl]);
            if (ret == 0) {
                return 0;
            }
        }
        return 1;
    }

    Search.prototype.search = function() {
        for (this.length1 = this.isRec ? this.length1 : 0; this.length1 < this.sol; this.length1++) {
            for (this.urfIdx = this.isRec ? this.urfIdx : 0; this.urfIdx < 6; this.urfIdx++) {
                if ((this.conjMask & 1 << this.urfIdx) != 0) {
                    continue;
                }
                if (this.phase1PreMoves(this.maxPreMoves, -30, this.urfCubieCube[this.urfIdx], 0) == 0) {
                    return this.moveSol == null ? "Error 8" : this.moveSol;
                }
            }
        }
        return this.moveSol == null ? "Error 7" : this.moveSol;
    }

    Search.prototype.initPhase2Pre = function() {
        this.isRec = false;
        if (this.probe >= (this.moveSol == null ? this.probeMax : this.probeMin)) {
            return 0;
        }
        ++this.probe;

        for (var i = this.valid1; i < this.depth1; i++) {
            CubieCube.CornMult(this.phase1Cubie[i], moveCube[this.move[i]], this.phase1Cubie[i + 1]);
            CubieCube.EdgeMult(this.phase1Cubie[i], moveCube[this.move[i]], this.phase1Cubie[i + 1]);
        }
        this.valid1 = this.depth1;

        var ret = this.initPhase2(this.phase1Cubie[this.depth1]);
        if (ret == 0 || this.preMoveLen == 0 || ret == 2) {
            return ret;
        }

        var m = ~~(this.preMoves[this.preMoveLen - 1] / 3) * 3 + 1;
        CubieCube.CornMult(moveCube[m], this.phase1Cubie[this.depth1], this.phase1Cubie[this.depth1 + 1]);
        CubieCube.EdgeMult(moveCube[m], this.phase1Cubie[this.depth1], this.phase1Cubie[this.depth1 + 1]);

        this.preMoves[this.preMoveLen - 1] += 2 - this.preMoves[this.preMoveLen - 1] % 3 * 2;
        ret = this.initPhase2(this.phase1Cubie[this.depth1 + 1]);
        this.preMoves[this.preMoveLen - 1] += 2 - this.preMoves[this.preMoveLen - 1] % 3 * 2;
        return ret;
    }
    Search.prototype.initPhase2 = function(phase2Cubie) {
        var p2corn = phase2Cubie.getCPermSym();
        var p2csym = p2corn & 0xf;
        p2corn >>= 4;
        var p2edge = phase2Cubie.getEPermSym();
        var p2esym = p2edge & 0xf;
        p2edge >>= 4;
        var p2mid = phase2Cubie.getMPerm();
        var prun = Math.max(
            getPruningMax(EPermCCombPPrunMax, EPermCCombPPrun,
                p2edge * N_COMB + CCombPConj[Perm2CombP[p2corn] & 0xff][SymMultInv[p2esym][p2csym]]),
            getPruningMax(MCPermPrunMax, MCPermPrun,
                p2corn * N_MPERM + MPermConj[p2mid][p2csym]));
        var maxDep2 = Math.min(MAX_DEPTH2, this.sol - this.length1);
        if (prun >= maxDep2) {
            return prun > maxDep2 ? 2 : 1;
        }
        var depth2;
        for (depth2 = maxDep2 - 1; depth2 >= prun; depth2--) {
            var ret = this.phase2(p2edge, p2esym, p2corn, p2csym, p2mid, depth2, this.depth1, 10);
            if (ret < 0) {
                break;
            }
            depth2 -= ret;
            this.moveSol = [];
            for (var i = 0; i < this.depth1 + depth2; i++) {
                this.appendSolMove(this.move[i]);
            }
            for (var i = this.preMoveLen - 1; i >= 0; i--) {
                this.appendSolMove(this.preMoves[i]);
            }
            this.sol = this.moveSol.length;
            this.moveSol = this.solutionToString();
        }
        if (depth2 != maxDep2 - 1) { //At least one solution has been found.
            return this.probe >= this.probeMin ? 0 : 1;
        } else {
            return 1;
        }
    }
    Search.prototype.phase1 = function(node, maxl, lm) {
        if (node.prun == 0 && maxl < 5) {
            if (this.allowShorter || maxl == 0) {
                this.depth1 -= maxl;
                var ret = this.initPhase2Pre();
                this.depth1 += maxl;
                return ret;
            } else {
                return 1;
            }
        }
        for (var axis = 0; axis < 18; axis += 3) {
            if (axis == lm || axis == lm - 9) {
                continue;
            }
            for (var power = 0; power < 3; power++) {
                var m = axis + power;

                if (this.isRec && m != this.move[this.depth1 - maxl]) {
                    continue;
                }

                var prun = this.nodeUD[maxl].doMovePrun(node, m, true);
                if (prun > maxl) {
                    break;
                } else if (prun == maxl) {
                    continue;
                }

                if (USE_CONJ_PRUN) {
                    prun = this.nodeUD[maxl].doMovePrunConj(node, m);
                    if (prun > maxl) {
                        break;
                    } else if (prun == maxl) {
                        continue;
                    }
                }
                this.move[this.depth1 - maxl] = m;
                this.valid1 = Math.min(this.valid1, this.depth1 - maxl);
                var ret = this.phase1(this.nodeUD[maxl], maxl - 1, axis);
                if (ret == 0) {
                    return 0;
                } else if (ret == 2) {
                    break;
                }
            }
        }
        return 1;
    }
    Search.prototype.appendSolMove = function(curMove) {
        if (this.moveSol.length == 0) {
            this.moveSol.push(curMove);
            return;
        }
        var axisCur = ~~(curMove / 3);
        var axisLast = ~~(this.moveSol[this.moveSol.length - 1] / 3);
        if (axisCur == axisLast) {
            var pow = (curMove % 3 + this.moveSol[this.moveSol.length - 1] % 3 + 1) % 4;
            if (pow == 3) {
                this.moveSol.pop();
            } else {
                this.moveSol[this.moveSol.length - 1] = axisCur * 3 + pow;
            }
            return;
        }
        if (this.moveSol.length > 1 &&
            axisCur % 3 == axisLast % 3 &&
            axisCur == ~~(this.moveSol[this.moveSol.length - 2] / 3)) {
            var pow = (curMove % 3 + this.moveSol[this.moveSol.length - 2] % 3 + 1) % 4;
            if (pow == 3) {
                this.moveSol[this.moveSol.length - 2] = this.moveSol[this.moveSol.length - 1];
                this.moveSol.pop();
            } else {
                this.moveSol[this.moveSol.length - 2] = axisCur * 3 + pow;
            }
            return;
        }
        this.moveSol.push(curMove);
    }
    Search.prototype.phase2 = function(edge, esym, corn, csym, mid, maxl, depth, lm) {
        if (edge == 0 && corn == 0 && mid == 0) {
            return maxl;
        }
        var moveMask = ckmv2bit[lm];
        for (var m = 0; m < 10; m++) {
            if ((moveMask >> m & 1) != 0) {
                m += 0x42 >> m & 3;
                continue;
            }
            var midx = MPermMove[mid][m];
            var cornx = CPermMove[corn][SymMoveUD[csym][m]];
            var csymx = SymMult[cornx & 0xf][csym];
            cornx >>= 4;
            if (getPruningMax(MCPermPrunMax, MCPermPrun,
                    cornx * N_MPERM + MPermConj[midx][csymx]) >= maxl) {
                continue;
            }
            var edgex = EPermMove[edge][SymMoveUD[esym][m]];
            var esymx = SymMult[edgex & 0xf][esym];
            edgex >>= 4;
            if (getPruningMax(EPermCCombPPrunMax, EPermCCombPPrun,
                    edgex * N_COMB + CCombPConj[Perm2CombP[cornx] & 0xff][SymMultInv[esymx][csymx]]) >= maxl) {
                continue;
            }
            var edgei = getPermSymInv(edgex, esymx, false);
            var corni = getPermSymInv(cornx, csymx, true);
            if (getPruningMax(EPermCCombPPrunMax, EPermCCombPPrun,
                    (edgei >> 4) * N_COMB + CCombPConj[Perm2CombP[corni >> 4] & 0xff][SymMultInv[edgei & 0xf][corni & 0xf]]) >= maxl) {
                continue;
            }

            var ret = this.phase2(edgex, esymx, cornx, csymx, midx, maxl - 1, depth + 1, m);
            if (ret >= 0) {
                this.move[depth] = ud2std[m];
                return ret;
            }
        }
        return -1;
    }
    Search.prototype.solutionToString = function() {
        var sb = '';
        var urf = (this.verbose & INVERSE_SOLUTION) != 0 ? (this.urfIdx + 3) % 6 : this.urfIdx;
        if (urf < 3) {
            for (var s = 0; s < this.moveSol.length; ++s) {
                sb += move2str[urfMove[urf][this.moveSol[s]]] + ' ';
            }
        } else {
            for (var s = this.moveSol.length - 1; s >= 0; --s) {
                sb += move2str[urfMove[urf][this.moveSol[s]]] + ' ';
            }
        }
        return sb;
    }

    var moveCube = [];
    var SymCube = [];
    var SymMult = [];
    var SymMultInv = [];
    var SymMove = [];
    var SymMoveUD = [];
    var Sym8Move = [];
    var FlipS2R = [];
    var FlipR2S = [];
    var TwistS2R = [];
    var TwistR2S = [];
    var EPermS2R = [];
    var EPermR2S = [];
    var SymStateFlip = [];
    var SymStateTwist = [];
    var SymStatePerm = [];
    var FlipS2RF = [];
    var Perm2CombP = [];
    var PermInvEdgeSym = [];
    var UDSliceMove = [];
    var TwistMove = [];
    var FlipMove = [];
    var UDSliceConj = [];
    var UDSliceTwistPrun = [];
    var UDSliceFlipPrun = [];
    var TwistFlipPrun = [];

    //phase2
    var CPermMove = [];
    var EPermMove = [];
    var MPermMove = [];
    var MPermConj = [];
    var CCombPMove = []; // = new char[N_COMB][N_MOVES2];
    var CCombPConj = [];
    var MCPermPrun = [];
    var EPermCCombPPrun = [];

    var TwistFlipPrunMax = 15;
    var UDSliceTwistPrunMax = 15;
    var UDSliceFlipPrunMax = 15;
    var MCPermPrunMax = 15;
    var EPermCCombPPrunMax = 15;

    { //init move cubes
        for (var i = 0; i < 18; i++) {
            moveCube[i] = new CubieCube()
        }
        moveCube[0].initCoord(15120, 0, 119750400, 0);
        moveCube[3].initCoord(21021, 1494, 323403417, 0);
        moveCube[6].initCoord(8064, 1236, 29441808, 550);
        moveCube[9].initCoord(9, 0, 5880, 0);
        moveCube[12].initCoord(1230, 412, 2949660, 0);
        moveCube[15].initCoord(224, 137, 328552, 137);
        for (var a = 0; a < 18; a += 3) {
            for (var p = 0; p < 2; p++) {
                CubieCube.EdgeMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
                CubieCube.CornMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
            }
        }
        CubieCube.urf1 = new CubieCube().initCoord(2531, 1373, 67026819, 1367);
        CubieCube.urf2 = new CubieCube().initCoord(2089, 1906, 322752913, 2040);
    }

    function initBasic() {
        { //init sym cubes
            var c = new CubieCube();
            var d = new CubieCube();
            var t;

            var f2 = new CubieCube().initCoord(28783, 0, 259268407, 0);
            var u4 = new CubieCube().initCoord(15138, 0, 119765538, 7);
            var lr2 = new CubieCube().initCoord(5167, 0, 83473207, 0);
            for (var i = 0; i < 8; i++) {
                lr2.ca[i] |= 3 << 3;
            }
            for (var i = 0; i < 16; i++) {
                SymCube[i] = new CubieCube().init(c.ca, c.ea);
                CubieCube.CornMultFull(c, u4, d);
                CubieCube.EdgeMult(c, u4, d);
                c.init(d.ca, d.ea);
                if (i % 4 == 3) {
                    CubieCube.CornMultFull(c, lr2, d);
                    CubieCube.EdgeMult(c, lr2, d);
                    c.init(d.ca, d.ea);
                }
                if (i % 8 == 7) {
                    CubieCube.CornMultFull(c, f2, d);
                    CubieCube.EdgeMult(c, f2, d);
                    c.init(d.ca, d.ea);
                }
            }
        } { // gen sym tables


            for (var i = 0; i < 16; i++) {
                SymMult[i] = [];
                SymMultInv[i] = [];
                SymMove[i] = [];
                Sym8Move[i] = [];
                SymMoveUD[i] = [];
            }
            for (var i = 0; i < 16; i++) {
                for (var j = 0; j < 16; j++) {
                    SymMult[i][j] = i ^ j ^ (0x14ab4 >> j & i << 1 & 2); // SymMult[i][j] = (i ^ j ^ (0x14ab4 >> j & i << 1 & 2)));
                    SymMultInv[SymMult[i][j]][j] = i;
                }
            }

            var c = new CubieCube();
            for (var s = 0; s < 16; s++) {
                for (var j = 0; j < 18; j++) {
                    CubieCube.CornConjugate(moveCube[j], SymMultInv[0][s], c);
                    outloop: for (var m = 0; m < 18; m++) {
                        for (var t = 0; t < 8; t++) {
                            if (moveCube[m].ca[t] != c.ca[t]) {
                                continue outloop;
                            }
                        }
                        SymMove[s][j] = m;
                        SymMoveUD[s][std2ud[j]] = std2ud[m];
                        break;
                    }
                    if (s % 2 == 0) {
                        Sym8Move[j << 3 | s >> 1] = SymMove[s][j];
                    }
                }
            }
        } { // init sym 2 raw tables
            function initSym2Raw(N_RAW, Sym2Raw, Raw2Sym, SymState, coord, setFunc, getFunc) {
                var N_RAW_HALF = (N_RAW + 1) >> 1;
                var c = new CubieCube();
                var d = new CubieCube();
                var count = 0;
                var sym_inc = coord >= 2 ? 1 : 2;
                var conjFunc = coord != 1 ? CubieCube.EdgeConjugate : CubieCube.CornConjugate;

                for (var i = 0; i < N_RAW; i++) {
                    if (Raw2Sym[i] !== undefined) {
                        continue;
                    }
                    setFunc.call(c, i);
                    for (var s = 0; s < 16; s += sym_inc) {
                        conjFunc(c, s, d);
                        var idx = getFunc.call(d);
                        if (USE_TWIST_FLIP_PRUN && coord == 0) {
                            FlipS2RF[count << 3 | s >> 1] = idx;
                        }
                        if (idx == i) {
                            SymState[count] |= 1 << (s / sym_inc);
                        }
                        Raw2Sym[idx] = (count << 4 | s) / sym_inc;
                    }
                    Sym2Raw[count++] = i;
                }
                return count;
            }

            initSym2Raw(N_FLIP, FlipS2R, FlipR2S, SymStateFlip, 0, CubieCube.prototype.setFlip, CubieCube.prototype.getFlip);
            initSym2Raw(N_TWIST, TwistS2R, TwistR2S, SymStateTwist, 1, CubieCube.prototype.setTwist, CubieCube.prototype.getTwist);
            initSym2Raw(N_PERM, EPermS2R, EPermR2S, SymStatePerm, 2, CubieCube.prototype.setEPerm, CubieCube.prototype.getEPerm);
            var cc = new CubieCube();
            for (var i = 0; i < N_PERM_SYM; i++) {
                setNPerm(cc.ea, EPermS2R[i], 8, true);
                Perm2CombP[i] = getComb(cc.ea, 0, true) + (USE_COMBP_PRUN ? getNParity(EPermS2R[i], 8) * 70 : 0);
                c.invFrom(cc);
                PermInvEdgeSym[i] = EPermR2S[c.getEPerm()];
            }
        } { // init coord tables

            var c = new CubieCube();
            var d = new CubieCube();

            function initSymMoveTable(moveTable, SymS2R, N_SIZE, N_MOVES, setFunc, getFunc, multFunc, ud2std) {
                for (var i = 0; i < N_SIZE; i++) {
                    moveTable[i] = [];
                    setFunc.call(c, SymS2R[i]);
                    for (var j = 0; j < N_MOVES; j++) {
                        multFunc(c, moveCube[ud2std ? ud2std[j] : j], d);
                        moveTable[i][j] = getFunc.call(d);
                    }
                }
            }

            initSymMoveTable(FlipMove, FlipS2R, N_FLIP_SYM, N_MOVES,
                CubieCube.prototype.setFlip, CubieCube.prototype.getFlipSym, CubieCube.EdgeMult);
            initSymMoveTable(TwistMove, TwistS2R, N_TWIST_SYM, N_MOVES,
                CubieCube.prototype.setTwist, CubieCube.prototype.getTwistSym, CubieCube.CornMult);
            initSymMoveTable(EPermMove, EPermS2R, N_PERM_SYM, N_MOVES2,
                CubieCube.prototype.setEPerm, CubieCube.prototype.getEPermSym, CubieCube.EdgeMult, ud2std);
            initSymMoveTable(CPermMove, EPermS2R, N_PERM_SYM, N_MOVES2,
                CubieCube.prototype.setCPerm, CubieCube.prototype.getCPermSym, CubieCube.CornMult, ud2std);

            for (var i = 0; i < N_SLICE; i++) {
                UDSliceMove[i] = [];
                UDSliceConj[i] = [];
                c.setUDSlice(i);
                for (var j = 0; j < N_MOVES; j++) {
                    CubieCube.EdgeMult(c, moveCube[j], d);
                    UDSliceMove[i][j] = d.getUDSlice();
                }
                for (var j = 0; j < 16; j += 2) {
                    CubieCube.EdgeConjugate(c, SymMultInv[0][j], d);
                    UDSliceConj[i][j >> 1] = d.getUDSlice();
                }
            }

            for (var i = 0; i < N_MPERM; i++) {
                MPermMove[i] = [];
                MPermConj[i] = [];
                c.setMPerm(i);
                for (var j = 0; j < N_MOVES2; j++) {
                    CubieCube.EdgeMult(c, moveCube[ud2std[j]], d);
                    MPermMove[i][j] = d.getMPerm();
                }
                for (var j = 0; j < 16; j++) {
                    CubieCube.EdgeConjugate(c, SymMultInv[0][j], d);
                    MPermConj[i][j] = d.getMPerm();
                }
            }

            for (var i = 0; i < N_COMB; i++) {
                CCombPMove[i] = [];
                CCombPConj[i] = [];
                c.setCComb(i % 70);
                for (var j = 0; j < N_MOVES2; j++) {
                    CubieCube.CornMult(c, moveCube[ud2std[j]], d);
                    CCombPMove[i][j] = d.getCComb() + 70 * ((P2_PARITY_MOVE >> j & 1) ^ ~~(i / 70));
                }
                for (var j = 0; j < 16; j++) {
                    CubieCube.CornConjugate(c, SymMultInv[0][j], d);
                    CCombPConj[i][j] = d.getCComb() + 70 * ~~(i / 70);
                }
            }
        }
    }

    //init pruning tables
    var InitPrunProgress = -1;

    function initRawSymPrun(PrunTable, N_RAW, N_SYM, RawMove, RawConj, SymMove, SymState, PrunFlag) {
        var SYM_SHIFT = PrunFlag & 0xf;
        var SYM_E2C_MAGIC = ((PrunFlag >> 4) & 1) == 1 ? 0x00DDDD00 : 0x00000000;
        var IS_PHASE2 = ((PrunFlag >> 5) & 1) == 1;
        var INV_DEPTH = PrunFlag >> 8 & 0xf;
        var MAX_DEPTH = PrunFlag >> 12 & 0xf;
        var MIN_DEPTH = PrunFlag >> 16 & 0xf;

        var SYM_MASK = (1 << SYM_SHIFT) - 1;
        var ISTFP = RawMove == null;
        var N_SIZE = N_RAW * N_SYM;
        var N_MOVES = IS_PHASE2 ? 10 : 18;
        var NEXT_AXIS_MAGIC = N_MOVES == 10 ? 0x42 : 0x92492;

        var depth = getPruning(PrunTable, N_SIZE) - 1;

        if (depth == -1) {
            for (var i = 0; i < (N_SIZE >> 3) + 1; i++) {
                PrunTable[i] = 0xffffffff;
            }
            setPruning(PrunTable, 0, 0 ^ 0xf);
            depth = 0;
        } else {
            setPruning(PrunTable, N_SIZE, 0xf ^ (depth + 1));
        }

        var SEARCH_DEPTH = PARTIAL_INIT_LEVEL > 0 ?
            Math.min(Math.max(depth + 1, MIN_DEPTH), MAX_DEPTH) : MAX_DEPTH;

        while (depth < SEARCH_DEPTH) {
            var inv = depth > INV_DEPTH;
            var select = inv ? 0xf : depth;
            var selArrMask = select * 0x11111111;
            var check = inv ? depth : 0xf;
            depth++;
            InitPrunProgress++;
            var xorVal = depth ^ 0xf;
            var done = 0;
            var val = 0;
            for (var i = 0; i < N_SIZE; i++, val >>= 4) {
                if ((i & 7) == 0) {
                    val = PrunTable[i >> 3];
                    if (!hasZero(val ^ selArrMask)) {
                        i += 7;
                        continue;
                    }
                }
                if ((val & 0xf) != select) {
                    continue;
                }
                var raw = i % N_RAW;
                var sym = ~~(i / N_RAW);
                var flip = 0,
                    fsym = 0;
                if (ISTFP) {
                    flip = FlipR2S[raw];
                    fsym = flip & 7;
                    flip >>= 3;
                }

                for (var m = 0; m < N_MOVES; m++) {
                    var symx = SymMove[sym][m];
                    var rawx;
                    if (ISTFP) {
                        rawx = FlipS2RF[
                            FlipMove[flip][Sym8Move[m << 3 | fsym]] ^
                            fsym ^ (symx & SYM_MASK)];
                    } else {
                        rawx = RawConj[RawMove[raw][m]][symx & SYM_MASK];
                    }
                    symx >>= SYM_SHIFT;
                    var idx = symx * N_RAW + rawx;
                    var prun = getPruning(PrunTable, idx);
                    if (prun != check) {
                        if (prun < depth - 1) {
                            m += NEXT_AXIS_MAGIC >> m & 3;
                        }
                        continue;
                    }
                    done++;
                    if (inv) {
                        setPruning(PrunTable, i, xorVal);
                        break;
                    }
                    setPruning(PrunTable, idx, xorVal);
                    for (var j = 1, symState = SymState[symx];
                        (symState >>= 1) != 0; j++) {
                        if ((symState & 1) != 1) {
                            continue;
                        }
                        var idxx = symx * N_RAW;
                        if (ISTFP) {
                            idxx += FlipS2RF[FlipR2S[rawx] ^ j];
                        } else {
                            idxx += RawConj[rawx][j ^ (SYM_E2C_MAGIC >> (j << 1) & 3)];
                        }
                        if (getPruning(PrunTable, idxx) == check) {
                            setPruning(PrunTable, idxx, xorVal);
                            done++;
                        }
                    }
                }
            }
            // console.log(depth, done, InitPrunProgress);
        }
        setPruning(PrunTable, N_SIZE, (depth + 1) ^ 0xf);
        return depth + 1;
    }

    function doInitPrunTables(targetProgress) {
        if (USE_TWIST_FLIP_PRUN) {
            TwistFlipPrunMax = initRawSymPrun(
                TwistFlipPrun, 2048, 324,
                null, null,
                TwistMove, SymStateTwist, 0x19603
            );
        }
        if (InitPrunProgress > targetProgress) {
            return;
        }
        UDSliceTwistPrunMax = initRawSymPrun(
            UDSliceTwistPrun, 495, 324,
            UDSliceMove, UDSliceConj,
            TwistMove, SymStateTwist, 0x69603
        );
        if (InitPrunProgress > targetProgress) {
            return;
        }
        UDSliceFlipPrunMax = initRawSymPrun(
            UDSliceFlipPrun, 495, 336,
            UDSliceMove, UDSliceConj,
            FlipMove, SymStateFlip, 0x69603
        );
        if (InitPrunProgress > targetProgress) {
            return;
        }
        MCPermPrunMax = initRawSymPrun(
            MCPermPrun, 24, 2768,
            MPermMove, MPermConj,
            CPermMove, SymStatePerm, 0x8ea34
        );
        if (InitPrunProgress > targetProgress) {
            return;
        }
        EPermCCombPPrunMax = initRawSymPrun(
            EPermCCombPPrun, N_COMB, 2768,
            CCombPMove, CCombPConj,
            EPermMove, SymStatePerm, 0x7d824
        );
    }

    function initPrunTables() {
        if (InitPrunProgress < 0) {
            initBasic();
            InitPrunProgress = 0;
        }
        if (InitPrunProgress == 0) {
            doInitPrunTables(99);
        } else if (InitPrunProgress < 54) {
            doInitPrunTables(InitPrunProgress);
        } else {
            return true;
        }
        return false;
    }

    function randomCube() {
        var ep, cp;
        var eo = ~~(Math.random() * 2048);
        var co = ~~(Math.random() * 2187);
        do {
            ep = ~~(Math.random() * fact[12]);
            cp = ~~(Math.random() * fact[8]);
        } while (getNParity(cp, 8) != getNParity(ep, 12));
        var cc = new CubieCube().initCoord(cp, co, ep, eo);
        return cc.toFaceCube();
    }
    return {
        Search: Search,
        solve: function(facelet) {
            return new Search().solution(facelet);
        },
        randomCube: randomCube,
        initFull: function() {
            PARTIAL_INIT_LEVEL = 0;
            initPrunTables();
        }
    }
})();

if (typeof module !== 'undefined' && typeof module.exports !== 'undefined') {
    module.exports = min2phase;
}

"use strict";

//
//  Version     File name           Description
//  -------     ---------           -----------
//  2004-12-03  hr$mersennetwister.js       original version will stay available,
//                          but is no longer maintained by Henk Reints
//
//  2005-11-02  hr$mersennetwister2.js      o  renamed constructor from "MersenneTwister"
//                             to "MersenneTwisterObject"
//                          o  exposure of methods now in separate section near the end
//                          o  removed "this." from internal references
//
// ====================================================================================================================
// Mersenne Twister mt19937ar, a pseudorandom generator by Takuji Nishimura and Makoto Matsumoto.
// Object Oriented JavaScript version by Henk Reints (http://henk-reints.nl)
// ====================================================================================================================
// Original header text from the authors (reformatted a little bit by HR):
// -----------------------------------------------------------------------
//
//  A C-program for MT19937, with initialization improved 2002/1/26.
//  Coded by Takuji Nishimura and Makoto Matsumoto.
//
//  Before using, initialize the state by using init_genrand(seed) or init_by_array(init_key, key_length).
//
//  Copyright (C) 1997 - 2002, Makoto Matsumoto and Takuji Nishimura, All rights reserved.
//
//  Redistribution and use in source and binary forms, with or without modification,
//  are permitted provided that the following conditions are met:
//
//  1. Redistributions of source code must retain the above copyright notice,
//     this list of conditions and the following disclaimer.
//
//  2. Redistributions in binary form must reproduce the above copyright notice,
//     this list of conditions and the following disclaimer in the documentation and/or
//     other materials provided with the distribution.
//
//  3. The names of its contributors may not be used to endorse or promote products derived from this software
//     without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
//  WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
//  PARTICULAR PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
//  ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
//  TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
//  HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
//  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
//  Any feedback is very welcome.
//  http://www.math.sci.hiroshima-u.ac.jp/~m-mat/MT/emt.html
//  email: m-mat @ math.sci.hiroshima-u.ac.jp (remove space)
//
// ====================================================================================================================
// Remarks by Henk Reints about this JS version:
//
// Legal stuff:
//  THE ABOVE LEGAL NOTICES AND DISCLAIMER BY THE ORIGINAL AUTHORS
//  ALSO APPLY TO THIS JAVASCRIPT TRANSLATION BY HENK REINTS.
//
// Contact:
//  For feedback or questions you can find me on the internet: http://henk-reints.nl
//
// Description:
//  This is an Object Oriented JavaScript version of the Mersenne Twister.
//
// Constructor:
//  MersenneTwisterObject([seed[,seedArray]])
//      if called with 0 args then a default seed   is used for initialisation by the 'init' method;
//      if called with 1 arg  then 'seed'           is used for initialisation by the 'init' method;
//      if called with 2 args then 'seedArray,seed' is used for initialisation by the 'initByArray' method;
//      if a supplied seed is NaN or not given then a default is used.
//
// Properties:
//  none exposed
//
// Methods:
//  init0(seed)     initialises the state array using the original algorithm
//                if seed is NaN or not given then a default is used
//  init(seed)      initialises the state array using the improved algorithm
//                if seed is NaN or not given then a default is used
//  initByArray(seedArray[,seed])
//              initialises the state array based on an array of seeds,
//                the 2nd argument is optional, if given and not NaN then it overrides
//                the default seed which is used for the very first initialisation
//  skip(n)         lets the random number generator skip a given count of randoms
//                if n <= 0 then it advances to the next scrambling round
//                in order to produce an unpredictable well-distributed sequence, you could let n be
//                generated by some other random generator which preferrably uses external events to
//                create an entropy pool from which to take the numbers.
//                this method has been added by Henk Reints, 2004-11-16.
//  randomInt32()       returns a random 32-bit integer
//  randomInt53()       returns a random 53-bit integer
//                this is done in the same way as was introduced 2002/01/09 by Isaku Wada
//                in his genrand_res53() function
//  randomReal32()      returns a random floating point number in [0,1) with 32-bit precision
//                please note that - at least on Microsoft Platforms - JavaScript ALWAYS stores
//                Numbers with a 53 bit mantissa, so randomReal32() is not the best choice in JS.
//                it is provided to be able to produce output that can be compared to the demo
//                output given by the original authors. For JavaScript implementations I suggest
//                you always use the randomReal53 method.
//  randomReal53()      returns a random floating point number in [0,1) with 53-bit precision
//                this is done in the same way as was introduced 2002/01/09 by Isaku Wada
//                in the genrand_res53() function
//  randomString(len)   returns a random string of given length, existing of chars from the charset:
//                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", which is identical
//                to the character set used for base64 encoding, so effectively it generates a random
//                base64-encoded number of arbitrary precision.
//                If you intend to use a random string in a URL string, then the "+" and "/" should
//                be converted to URL syntax using the JavaScript built-in 'escape' method.
//                this method has been added by Henk Reints, 2004-11-16.
//  random()        a synonym for randomReal53  [HR/2004-12-03]
//  randomInt()     a synonym for randomInt32   [HR/2004-12-03]
//                these two synonyms are intended to be generic names for normal use.
//
// Examples of object creation:
//  mt = new MersenneTwisterObject()            // create object with default initialisation
//  mt = new MersenneTwisterObject(19571118)        // create object using a specific seed
//  mt = new MersenneTwisterObject(Nan,[1957,11,18,03,06])  // create object using a seed array only
//  mt = new MersenneTwisterObject(1957,[11,18,03,06])  // create object using a seed array AND a specific seed
//
// Examples of (re)initialisation (to be done after the object has been created):
//  mt.init0()              // re-init using the old-style algorithm with its default seed
//  mt.init0(181157)            // re-init using the old-style algorithm with a given seed
//  mt.init()               // re-init using the new-style algorithm with its default seed
//  mt.init(181157)             // re-init using the new-style algorithm with a given seed
//  mt.initByArray([18,11,57])      // re-init using a seed array
//  mt.initByArray([18,11,57],0306)     // re-init using a seed array AND a specific seed
//
// Example of generating random numbers (after creation of the object and optional re-initialisation of its state):
//  while (condition)
//  {   i = mt.randomInt32()            // get a random 32 bit integer
//      a = mt.randomReal53()           // and a random floating point number of maximum precision
//      x = myVerySophisticatedAlgorithm(i,a)   // do something with it
//  }
//
// Functions for internal use only:
//  dmul0(m,n)  performs double precision multiplication of two 32-bit integers and returns only the low order
//          32 bits of the product; this function is necessary because JS always stores Numbers with a
//          53-bit mantissa, leading to loss of 11 lowest order bits. In fact it is the pencil & paper
//          method for multiplying 2 numbers of 2 digits each, but it uses digits of 16-bits each. Since
//          only the low order result is needed, the steps that only affect the high order part of the
//          result are left out.
//
// Renamed original functions:          to:
//  init_genrand(s)             init(seed)
//  init_by_array(init_key,key_length)  initByArray(seedArray[,seed])
//  genrand_int32()             randomInt32()
//  genrand_real2()             randomReal32()
//  genrand_res53()             randomReal53()
//
// Other modifications w.r.t. the original:
//  - did not include the other variants returning real values - I think [0,1) is the only appropriate interval;
//  - included randomInt53() using the same method as was introduced 2002/01/09 by Isaku Wada in his genrand_res53;
//  - included randomString(len);
//  - included skip(n);
//  - in the randomInt32 method I have changed the check "if (mti >= N)" to a 'while' loop decrementing mti by N
//    in each iteration, which allows skipping a range of randoms by simply adding a value to the mti property.
//    By setting mti to a negative value you can force an advance to the next scrambling round.
//    Since in this library the uninitialised state is not marked by mti==N+1 that's is a safe algorithm.
//    When using the constructor, a default initialisation is always performed.
//
// Notes:
//  - Whenever I say 'random' in this file, I mean of course 'pseudorandom';
//  - I have tested this only with Windows Script Host V5.6 on 32-bit Microsoft Windows platforms.
//    If it does not produce correct results on other platforms, then please don't blame me!
//  - As mentioned by the authors and on many other internet sites,
//    the Mersenne Twister does _NOT_ produce secure sequences for cryptographic purposes!
//    It was primarily designed for producing good pseudorandom numbers to perform statistics.
// ====================================================================================================================

function MersenneTwisterObject(seed, seedArray) {
    var N = 624,
        mask = 0xffffffff,
        mt = [],
        mti = NaN,
        m01 = [0, 0x9908b0df]
    var M = 397,
        N1 = N - 1,
        NM = N - M,
        MN = M - N,
        U = 0x80000000,
        L = 0x7fffffff,
        R = 0x100000000

    function dmul0(m, n) {
        var H = 0xffff0000,
            L = 0x0000ffff,
            R = 0x100000000,
            m0 = m & L,
            m1 = (m & H) >>> 16,
            n0 = n & L,
            n1 = (n & H) >>> 16,
            p0, p1, x
        p0 = m0 * n0, p1 = p0 >>> 16, p0 &= L, p1 += m0 * n1, p1 &= L, p1 += m1 * n0, p1 &= L, x = (p1 << 16) | p0
        return (x < 0 ? x + R : x)
    }

    function init0(seed) {
        var x = (arguments.length > 0 && isFinite(seed) ? seed & mask : 4357),
            i
        for (mt = [x], mti = N, i = 1; i < N; mt[i++] = x = (69069 * x) & mask) {}
    }

    function init(seed) {
        var x = (arguments.length > 0 && isFinite(seed) ? seed & mask : 5489),
            i
        for (mt = [x], mti = N, i = 1; i < N; mt[i] = x = dmul0(x ^ (x >>> 30), 1812433253) + i++) {}
    }

    function initByArray(seedArray, seed) {
        var N1 = N - 1,
            L = seedArray.length,
            x, i, j, k
        init(arguments.length > 1 && isFinite(seed) ? seed : 19650218)
        x = mt[0], i = 1, j = 0, k = Math.max(N, L)
        for (; k; j %= L, k--) {
            mt[i] = x = ((mt[i++] ^ dmul0(x ^ (x >>> 30), 1664525)) + seedArray[j] + j++) & mask
            if (i > N1) {
                mt[0] = x = mt[N1];
                i = 1
            }
        }
        for (k = N - 1; k; k--) {
            mt[i] = x = ((mt[i] ^ dmul0(x ^ (x >>> 30), 1566083941)) - i++) & mask
            if (i > N1) {
                mt[0] = x = mt[N1];
                i = 1
            }
        }
        mt[0] = 0x80000000
    }

    function skip(n) {
        mti = (n <= 0 ? -1 : mti + n)
    }

    function randomInt32() {
        var y, k
        while (mti >= N || mti < 0) {
            mti = Math.max(0, mti - N)
            for (k = 0; k < NM; y = (mt[k] & U) | (mt[k + 1] & L), mt[k] = mt[k + M] ^ (y >>> 1) ^ m01[y & 1], k++) {}
            for (; k < N1; y = (mt[k] & U) | (mt[k + 1] & L), mt[k] = mt[k + MN] ^ (y >>> 1) ^ m01[y & 1], k++) {}
            y = (mt[N1] & U) | (mt[0] & L), mt[N1] = mt[M - 1] ^ (y >>> 1) ^ m01[y & 1]
        }
        y = mt[mti++], y ^= (y >>> 11), y ^= (y << 7) & 0x9d2c5680, y ^= (y << 15) & 0xefc60000, y ^= (y >>> 18)
        return (y < 0 ? y + R : y)
    }

    function randomInt53() {
        var two26 = 0x4000000
        return (randomInt32() >>> 5) * two26 + (randomInt32() >>> 6)
    }

    function randomReal32() {
        var two32 = 0x100000000
        return randomInt32() / two32
    }

    function randomReal53() {
        var two53 = 0x20000000000000
        return randomInt53() / two53
    }

    function randomString(len) {
        var i, r, x = "",
            C = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
        for (i = 0; i < len; x += C.charAt((((i++) % 5) > 0 ? r : r = randomInt32()) & 63), r >>>= 6) {};
        return x
    }
    if (arguments.length > 1) initByArray(seedArray, seed)
    else if (arguments.length > 0) init(seed)
    else init()
    return randomReal53;
}
// ====================================================================================================================
// End of file hr$mersennetwister2.js - Copyright (c) 2004,2005 Henk Reints, http://henk-reints.nl

Math.random = new MersenneTwisterObject(new Date().getTime());

"use strict";



/*
scramble_333.js
3x3x3 Solver / Scramble Generator in Javascript.
The core 3x3x3 code is from a min2phase solver by Shuang Chen.
Compiled to Javascript using GWT.
(There may be a lot of redundant code right now, but it's still really fast.)
 */
"use strict";

var scramble_333 = (function(getNPerm, setNPerm, set8Perm, getNParity, rn, rndEl) {

    var Ux1 = 0,
        Ux2 = 1,
        Ux3 = 2,
        Rx1 = 3,
        Rx2 = 4,
        Rx3 = 5,
        Fx1 = 6,
        Fx2 = 7,
        Fx3 = 8,
        Dx1 = 9,
        Dx2 = 10,
        Dx3 = 11,
        Lx1 = 12,
        Lx2 = 13,
        Lx3 = 14,
        Bx1 = 15,
        Bx2 = 16,
        Bx3 = 17;

    function CubieCube_$$init(obj) {
        obj.cp = [0, 1, 2, 3, 4, 5, 6, 7];
        obj.co = [0, 0, 0, 0, 0, 0, 0, 0];
        obj.ep = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        obj.eo = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0];
    }

    function $setFlip(obj, idx) {
        var i, parity;
        parity = 0;
        for (i = 10; i >= 0; --i) {
            parity ^= obj.eo[i] = (idx & 1);
            idx >>= 1;
        }
        obj.eo[11] = parity;
    }

    function $setTwist(obj, idx) {
        var i, twst;
        twst = 0;
        for (i = 6; i >= 0; --i) {
            twst += obj.co[i] = idx % 3;
            idx = ~~(idx / 3);
        }
        obj.co[7] = (15 - twst) % 3;
    }

    function CornMult(a, b, prod) {
        var corn, ori, oriA, oriB;
        for (corn = 0; corn < 8; ++corn) {
            prod.cp[corn] = a.cp[b.cp[corn]];
            oriA = a.co[b.cp[corn]];
            oriB = b.co[corn];
            ori = oriA;
            ori += oriA < 3 ? oriB : 6 - oriB;
            ori %= 3;
            ((oriA >= 3) !== (oriB >= 3)) && (ori += 3);
            prod.co[corn] = ori;
        }
    }

    function CubieCube() {
        CubieCube_$$init(this);
    }

    function CubieCube1(cperm, twist, eperm, flip) {
        CubieCube_$$init(this);
        set8Perm(this.cp, cperm);
        $setTwist(this, twist);
        setNPerm(this.ep, eperm, 12);
        $setFlip(this, flip);
    }

    function EdgeMult(a, b, prod) {
        var ed;
        for (ed = 0; ed < 12; ++ed) {
            prod.ep[ed] = a.ep[b.ep[ed]];
            prod.eo[ed] = b.eo[ed] ^ a.eo[b.ep[ed]];
        }
    }

    function initMove() {
        var a, p;
        moveCube[0] = new CubieCube1(15120, 0, 119750400, 0);
        moveCube[3] = new CubieCube1(21021, 1494, 323403417, 0);
        moveCube[6] = new CubieCube1(8064, 1236, 29441808, 550);
        moveCube[9] = new CubieCube1(9, 0, 5880, 0);
        moveCube[12] = new CubieCube1(1230, 412, 2949660, 0);
        moveCube[15] = new CubieCube1(224, 137, 328552, 137);
        for (a = 0; a < 18; a += 3) {
            for (p = 0; p < 2; ++p) {
                moveCube[a + p + 1] = new CubieCube;
                EdgeMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
                CornMult(moveCube[a + p], moveCube[a], moveCube[a + p + 1]);
            }
        }
    }

    var _ = CubieCube1.prototype = CubieCube.prototype;
    var moveCube = [];
    var cornerFacelet = [
        [8, 9, 20],
        [6, 18, 38],
        [0, 36, 47],
        [2, 45, 11],
        [29, 26, 15],
        [27, 44, 24],
        [33, 53, 42],
        [35, 17, 51]
    ];
    var edgeFacelet = [
        [5, 10],
        [7, 19],
        [3, 37],
        [1, 46],
        [32, 16],
        [28, 25],
        [30, 43],
        [34, 52],
        [23, 12],
        [21, 41],
        [50, 39],
        [48, 14]
    ];

    function toFaceCube(cc) {
        var c, e, f, i, j, n, ori, ts;
        f = [];
        ts = [85, 82, 70, 68, 76, 66];
        for (i = 0; i < 54; ++i) {
            f[i] = ts[~~(i / 9)];
        }
        for (c = 0; c < 8; ++c) {
            j = cc.cp[c];
            ori = cc.co[c];
            for (n = 0; n < 3; ++n)
                f[cornerFacelet[c][(n + ori) % 3]] = ts[~~(cornerFacelet[j][n] / 9)];
        }
        for (e = 0; e < 12; ++e) {
            j = cc.ep[e];
            ori = cc.eo[e];
            for (n = 0; n < 2; ++n)
                f[edgeFacelet[e][(n + ori) % 2]] = ts[~~(edgeFacelet[j][n] / 9)];
        }
        return String.fromCharCode.apply(null, f);
    }


    // SCRAMBLERS

    var search = new min2phase.Search();

    function getRandomScramble() {
        return getAnyScramble(0xffffffffffff, 0xffffffffffff, 0xffffffff, 0xffffffff);
    }

    function getFMCScramble() {
        var scramble = "",
            axis1, axis2, axisl1, axisl2;
        do {
            scramble = getRandomScramble();
            var moveseq = scramble.split(' ');
            if (moveseq.length < 3) {
                continue;
            }
            axis1 = moveseq[0][0];
            axis2 = moveseq[1][0];
            axisl1 = moveseq[moveseq.length - 2][0];
            axisl2 = moveseq[moveseq.length - 3][0];
        } while (
            axis1 == 'F' || axis1 == 'B' && axis2 == 'F' ||
            axisl1 == 'R' || axisl1 == 'L' && axisl2 == 'R');
        return "R' U' F " + scramble + "R' U' F";
    }

    function cntU(b) {
        for (var c = 0, a = 0; a < b.length; a++) - 1 == b[a] && c++;
        return c
    }

    function fixOri(arr, cntU, base) {
        var sum = 0;
        var idx = 0;
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] != -1) {
                sum += arr[i];
            }
        }
        sum %= base;
        for (var i = 0; i < arr.length - 1; i++) {
            if (arr[i] == -1) {
                if (cntU-- == 1) {
                    arr[i] = ((base << 4) - sum) % base;
                } else {
                    arr[i] = rn(base);
                    sum += arr[i];
                }
            }
            idx *= base;
            idx += arr[i];
        }
        return idx;
    }

    function fixPerm(arr, cntU, parity) {
        var val = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11];
        for (var i = 0; i < arr.length; i++) {
            if (arr[i] != -1) {
                val[arr[i]] = -1;
            }
        }
        for (var i = 0, j = 0; i < val.length; i++) {
            if (val[i] != -1) {
                val[j++] = val[i];
            }
        }
        var last;
        for (var i = 0; i < arr.length && cntU > 0; i++) {
            if (arr[i] == -1) {
                var r = rn(cntU);
                arr[i] = val[r];
                for (var j = r; j < 11; j++) {
                    val[j] = val[j + 1];
                }
                if (cntU-- == 2) {
                    last = i;
                }
            }
        }
        if (getNParity(getNPerm(arr, arr.length), arr.length) == 1 - parity) {
            var temp = arr[i - 1];
            arr[i - 1] = arr[last];
            arr[last] = temp;
        }
        return getNPerm(arr, arr.length);
    }

    //arr: 53 bit integer
    function parseMask(arr, length) {
        if ('number' !== typeof arr) {
            return arr;
        }
        var ret = [];
        for (var i = 0; i < length; i++) {
            var val = arr & 0xf; // should use "/" instead of ">>" to avoid unexpected type conversion
            ret[i] = val == 15 ? -1 : val;
            arr /= 16;
        }
        return ret;
    }

    var aufsuff = [
        [],
        [Ux1],
        [Ux2],
        [Ux3]
    ];

    var rlpresuff = [
        [],
        [Rx1, Lx3],
        [Rx2, Lx2],
        [Rx3, Lx1]
    ];

    var rlappsuff = ["", "x'", "x2", "x"];

    var emptysuff = [
        []
    ];

    function getAnyScramble(_ep, _eo, _cp, _co, _rndapp, _rndpre) {
        initMove();
        _rndapp = _rndapp || emptysuff;
        _rndpre = _rndpre || emptysuff;
        _ep = parseMask(_ep, 12);
        _eo = parseMask(_eo, 12);
        _cp = parseMask(_cp, 8);
        _co = parseMask(_co, 8);
        var solution = "";
        do {
            var eo = _eo.slice();
            var ep = _ep.slice();
            var co = _co.slice();
            var cp = _cp.slice();
            var neo = fixOri(eo, cntU(eo), 2);
            var nco = fixOri(co, cntU(co), 3);
            var nep, ncp;
            var ue = cntU(ep);
            var uc = cntU(cp);
            if (ue == 0 && uc == 0) {
                nep = getNPerm(ep, 12);
                ncp = getNPerm(cp, 8);
            } else if (ue != 0 && uc == 0) {
                ncp = getNPerm(cp, 8);
                nep = fixPerm(ep, ue, getNParity(ncp, 8));
            } else if (ue == 0 && uc != 0) {
                nep = getNPerm(ep, 12);
                ncp = fixPerm(cp, uc, getNParity(nep, 12));
            } else {
                nep = fixPerm(ep, ue, -1);
                ncp = fixPerm(cp, uc, getNParity(nep, 12));
            }
            if (ncp + nco + nep + neo == 0) {
                continue;
            }
            var cc = new CubieCube1(ncp, nco, nep, neo);
            var cc2 = new CubieCube;
            var rndpre = rndEl(_rndpre);
            var rndapp = rndEl(_rndapp);
            for (var i = 0; i < rndpre.length; i++) {
                CornMult(moveCube[rndpre[i]], cc, cc2);
                EdgeMult(moveCube[rndpre[i]], cc, cc2);
                var tmp = cc2;
                cc2 = cc;
                cc = tmp;
            }
            for (var i = 0; i < rndapp.length; i++) {
                CornMult(cc, moveCube[rndapp[i]], cc2);
                EdgeMult(cc, moveCube[rndapp[i]], cc2);
                var tmp = cc2;
                cc2 = cc;
                cc = tmp;
            }
            var posit = toFaceCube(cc);
            var search0 = new min2phase.Search();
            solution = search0.solution(posit, 21, 1e9, 50, 2);
        } while (solution.length <= 3);
        return solution.replace(/ +/g, ' ');
    }

    function getEdgeScramble() {
        return getAnyScramble(0xffffffffffff, 0xffffffffffff, 0x76543210, 0x00000000);
    }

    function getCornerScramble() {
        return getAnyScramble(0xba9876543210, 0x000000000000, 0xffffffff, 0xffffffff);
    }

    function getLLScramble() {
        return getAnyScramble(0xba987654ffff, 0x00000000ffff, 0x7654ffff, 0x0000ffff);
    }

    var f2l_map = [
        0x2000, // Easy-01
        0x1011, // Easy-02
        0x2012, // Easy-03
        0x1003, // Easy-04
        0x2003, // RE-05
        0x1012, // RE-06
        0x2002, // RE-07
        0x1013, // RE-08
        0x2013, // REFC-09
        0x1002, // REFC-10
        0x2010, // REFC-11
        0x1001, // REFC-12
        0x2011, // REFC-13
        0x1000, // REFC-14
        0x2001, // SPGO-15
        0x1010, // SPGO-16
        0x0000, // SPGO-17
        0x0011, // SPGO-18
        0x0003, // PMS-19
        0x0012, // PMS-20
        0x0002, // PMS-21
        0x0013, // PMS-22
        0x0001, // Weird-23
        0x0010, // Weird-24
        0x0400, // CPEU-25
        0x0411, // CPEU-26
        0x1400, // CPEU-27
        0x2411, // CPEU-28
        0x1411, // CPEU-29
        0x2400, // CPEU-30
        0x0018, // EPCU-31
        0x0008, // EPCU-32
        0x2008, // EPCU-33
        0x1008, // EPCU-34
        0x2018, // EPCU-35
        0x1018, // EPCU-36
        0x0418, // ECP-37
        0x1408, // ECP-38
        0x2408, // ECP-39
        0x1418, // ECP-40
        0x2418, // ECP-41
        0x0408    // Solved-42
    ];

    var f2lprobs = [
        4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 1, 1, 1, 1, 1
    ];

    var f2lfilter = [
        'Easy-01', 'Easy-02', 'Easy-03', 'Easy-04', 'RE-05', 'RE-06', 'RE-07', 'RE-08', 'REFC-09', 'REFC-10', 'REFC-11', 'REFC-12', 'REFC-13', 'REFC-14', 'SPGO-15', 'SPGO-16', 'SPGO-17', 'SPGO-18', 'PMS-19', 'PMS-20', 'PMS-21', 'PMS-22', 'Weird-23', 'Weird-24', 'CPEU-25', 'CPEU-26', 'CPEU-27', 'CPEU-28', 'CPEU-29', 'CPEU-30', 'EPCU-31', 'EPCU-32', 'EPCU-33', 'EPCU-34', 'EPCU-35', 'EPCU-36', 'ECP-37', 'ECP-38', 'ECP-39', 'ECP-40', 'ECP-41', 'Solved-42'
    ];

    function getLSLLScramble(type, length, cases) {
        var caze = f2l_map[scrMgr.fixCase(cases, f2lprobs)];
        var ep = Math.pow(16, caze & 0xf);
        var eo = 0xf ^ (caze >> 4 & 1);
        var cp = Math.pow(16, caze >> 8 & 0xf);
        var co = 0xf ^ (caze >> 12 & 3);
        return getAnyScramble(0xba9f7654ffff - 7 * ep, 0x000f0000ffff - eo * ep, 0x765fffff - 0xb * cp, 0x000fffff - co * cp);
    }

    function getF2LScramble() {
        return getAnyScramble(0xffff7654ffff, 0xffff0000ffff, 0xffffffff, 0xffffffff);
    }

    var zbll_map = [
        [0x3210, 0x2121], // H-BBFF
        [0x3012, 0x2121], // H-FBFB
        [0x3120, 0x2121], // H-RFLF
        [0x3201, 0x2121], // H-RLFF
        [0x3012, 0x1020], // L-FBRL
        [0x3021, 0x1020], // L-LBFF
        [0x3201, 0x1020], // L-LFFB
        [0x3102, 0x1020], // L-LFFR
        [0x3210, 0x1020], // L-LRFF
        [0x3120, 0x1020], // L-RFBL
        [0x3102, 0x1122], // Pi-BFFB
        [0x3120, 0x1122], // Pi-FBFB
        [0x3012, 0x1122], // Pi-FRFL
        [0x3021, 0x1122], // Pi-FRLF
        [0x3210, 0x1122], // Pi-LFRF
        [0x3201, 0x1122], // Pi-RFFL
        [0x3120, 0x2220], // S-FBBF
        [0x3102, 0x2220], // S-FBFB
        [0x3210, 0x2220], // S-FLFR
        [0x3201, 0x2220], // S-FLRF
        [0x3021, 0x2220], // S-LFFR
        [0x3012, 0x2220], // S-LFRF
        [0x3210, 0x2100], // T-BBFF
        [0x3012, 0x2100], // T-FBFB
        [0x3201, 0x2100], // T-FFLR
        [0x3120, 0x2100], // T-FLFR
        [0x3102, 0x2100], // T-RFLF
        [0x3021, 0x2100], // T-RLFF
        [0x3021, 0x1200], // U-BBFF
        [0x3201, 0x1200], // U-BFFB
        [0x3012, 0x1200], // U-FFLR
        [0x3120, 0x1200], // U-FRLF
        [0x3102, 0x1200], // U-LFFR
        [0x3210, 0x1200], // U-LRFF
        [0x3102, 0x1101], // aS-FBBF
        [0x3120, 0x1101], // aS-FBFB
        [0x3012, 0x1101], // aS-FRFL
        [0x3021, 0x1101], // aS-FRLF
        [0x3210, 0x1101], // aS-LFRF
        [0x3201, 0x1101], // aS-RFFL
        [0xffff, 0x0000] // PLL
    ];

    var zbprobs = [1, 1, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3];

    var zbfilter = ['H-BBFF', 'H-FBFB', 'H-RFLF', 'H-RLFF', 'L-FBRL', 'L-LBFF', 'L-LFFB', 'L-LFFR', 'L-LRFF', 'L-RFBL', 'Pi-BFFB', 'Pi-FBFB', 'Pi-FRFL', 'Pi-FRLF', 'Pi-LFRF', 'Pi-RFFL', 'S-FBBF', 'S-FBFB', 'S-FLFR', 'S-FLRF', 'S-LFFR', 'S-LFRF', 'T-BBFF', 'T-FBFB', 'T-FFLR', 'T-FLFR', 'T-RFLF', 'T-RLFF', 'U-BBFF', 'U-BFFB', 'U-FFLR', 'U-FRLF', 'U-LFFR', 'U-LRFF', 'aS-FBBF', 'aS-FBFB', 'aS-FRFL', 'aS-FRLF', 'aS-LFRF', 'aS-RFFL', 'PLL'];

    function getZBLLScramble(type, length, cases) {
        var zbcase = zbll_map[scrMgr.fixCase(cases, zbprobs)];
        return getAnyScramble(0xba987654ffff, 0, zbcase[0] + 0x76540000, zbcase[1], aufsuff, aufsuff);
    }

    function getZZLLScramble() {
        return getAnyScramble(0xba9876543f1f, 0x000000000000, 0x7654ffff, 0x0000ffff, aufsuff);
    }

    function getZBLSScramble() {
        return getAnyScramble(0xba9f7654ffff, 0x000000000000, 0x765fffff, 0x000fffff);
    }

    function getLSEScramble() {
        var rnd4 = rn(4);
        return getAnyScramble(0xba98f6f4ffff, 0x0000f0f0ffff, 0x76543210, 0x00000000, [rlpresuff[rnd4]], aufsuff) + rlappsuff[rnd4];
    }

    var cmll_map = [
        0x0000, // O or solved
        0x1212, // H
        0x0102, // L
        0x1122, // Pi
        0x0222, // S
        0x0021, // T
        0x0012, // U
        0x0111 // aS
    ];
    var cmprobs = [6, 12, 24, 24, 24, 24, 24, 24];
    var cmfilter = ['O', 'H', 'L', 'Pi', 'S', 'T', 'U', 'aS'];

    function getCMLLScramble(type, length, cases) {
        var rnd4 = rn(4);
        var presuff = [];
        for (var i = 0; i < aufsuff.length; i++) {
            presuff.push(aufsuff[i].concat(rlpresuff[rnd4]));
        }
        return getAnyScramble(0xba98f6f4ffff, 0x0000f0f0ffff, 0x7654ffff, cmll_map[scrMgr.fixCase(cases, cmprobs)], presuff, aufsuff) + rlappsuff[rnd4];
    }

    function getCLLScramble() {
        return getAnyScramble(0xba9876543210, 0x000000000000, 0x7654ffff, 0x0000ffff);
    }

    function getELLScramble() {
        return getAnyScramble(0xba987654ffff, 0x00000000ffff, 0x76543210, 0x00000000);
    }

    function get2GLLScramble() {
        return getAnyScramble(0xba987654ffff, 0x000000000000, 0x76543210, 0x0000ffff, aufsuff);
    }

    var pll_map = [
        [0x1032, 0x3210], // H
        [0x3102, 0x3210], // Ua
        [0x3021, 0x3210], // Ub
        [0x2301, 0x3210], // Z
        [0x3210, 0x3021], // Aa
        [0x3210, 0x3102], // Ab
        [0x3210, 0x2301], // E
        [0x3012, 0x3201], // F
        [0x2130, 0x3021], // Gb
        [0x1320, 0x3102], // Ga
        [0x3021, 0x3102], // Gc
        [0x3102, 0x3021], // Gd
        [0x3201, 0x3201], // Ja
        [0x3120, 0x3201], // Jb
        [0x1230, 0x3012], // Na
        [0x3012, 0x3012], // Nb
        [0x0213, 0x3201], // Ra
        [0x2310, 0x3201], // Rb
        [0x1230, 0x3201], // T
        [0x3120, 0x3012], // V
        [0x3201, 0x3012] // Y
    ];

    var pllprobs = [
        1, 4, 4, 2,
        4, 4, 2, 4,
        4, 4, 4, 4,
        4, 4, 1, 1,
        4, 4, 4, 4, 4
    ];

    var pllfilter = [
        'H', 'Ua', 'Ub', 'Z',
        'Aa', 'Ab', 'E', 'F',
        'Ga', 'Gb', 'Gc', 'Gd',
        'Ja', 'Jb', 'Na', 'Nb',
        'Ra', 'Rb', 'T', 'V', 'Y'
    ];

    function getPLLScramble(type, length, cases) {
        var pllcase = pll_map[scrMgr.fixCase(cases, pllprobs)];
        return getAnyScramble(pllcase[0] + 0xba9876540000, 0x000000000000, pllcase[1] + 0x76540000, 0x00000000, aufsuff, aufsuff);
    }

    var oll_map = [
        [0x0000, 0x0000], // PLL
        [0x1111, 0x1212], // Point-1
        [0x1111, 0x1122], // Point-2
        [0x1111, 0x0222], // Point-3
        [0x1111, 0x0111], // Point-4
        [0x0011, 0x2022], // Square-5
        [0x0011, 0x1011], // Square-6
        [0x0011, 0x2202], // SLBS-7
        [0x0011, 0x0111], // SLBS-8
        [0x0011, 0x1110], // Fish-9
        [0x0011, 0x2220], // Fish-10
        [0x0011, 0x0222], // SLBS-11
        [0x0011, 0x1101], // SLBS-12
        [0x0101, 0x2022], // Knight-13
        [0x0101, 0x0111], // Knight-14
        [0x0101, 0x0222], // Knight-15
        [0x0101, 0x1011], // Knight-16
        [0x1111, 0x0102], // Point-17
        [0x1111, 0x0012], // Point-18
        [0x1111, 0x0021], // Point-19
        [0x1111, 0x0000], // CO-20
        [0x0000, 0x1212], // OCLL-21
        [0x0000, 0x1122], // OCLL-22
        [0x0000, 0x0012], // OCLL-23
        [0x0000, 0x0021], // OCLL-24
        [0x0000, 0x0102], // OCLL-25
        [0x0000, 0x0111], // OCLL-26
        [0x0000, 0x0222], // OCLL-27
        [0x0011, 0x0000], // CO-28
        [0x0011, 0x0210], // Awkward-29
        [0x0011, 0x2100], // Awkward-30
        [0x0011, 0x0021], // P-31
        [0x0011, 0x1002], // P-32
        [0x0101, 0x0021], // T-33
        [0x0101, 0x0210], // C-34
        [0x0011, 0x1020], // Fish-35
        [0x0011, 0x0102], // W-36
        [0x0011, 0x2010], // Fish-37
        [0x0011, 0x0201], // W-38
        [0x0101, 0x1020], // BLBS-39
        [0x0101, 0x0102], // BLBS-40
        [0x0011, 0x1200], // Awkward-41
        [0x0011, 0x0120], // Awkward-42
        [0x0011, 0x0012], // P-43
        [0x0011, 0x2001], // P-44
        [0x0101, 0x0012], // T-45
        [0x0101, 0x0120], // C-46
        [0x0011, 0x1221], // L-47
        [0x0011, 0x1122], // L-48
        [0x0011, 0x2112], // L-49
        [0x0011, 0x2211], // L-50
        [0x0101, 0x1221], // I-51
        [0x0101, 0x1122], // I-52
        [0x0011, 0x2121], // L-53
        [0x0011, 0x1212], // L-54
        [0x0101, 0x2121], // I-55
        [0x0101, 0x1212], // I-56
        [0x0101, 0x0000], // CO-57
    ];
    var ollprobs = [1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 1, 2, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 4, 2, 2, 2];
    var ollfilter = ['PLL', 'Point-1', 'Point-2', 'Point-3', 'Point-4', 'Square-5', 'Square-6', 'SLBS-7', 'SLBS-8', 'Fish-9', 'Fish-10', 'SLBS-11', 'SLBS-12', 'Knight-13', 'Knight-14', 'Knight-15', 'Knight-16', 'Point-17', 'Point-18', 'Point-19', 'CO-20', 'OCLL-21', 'OCLL-22', 'OCLL-23', 'OCLL-24', 'OCLL-25', 'OCLL-26', 'OCLL-27', 'CO-28', 'Awkward-29', 'Awkward-30', 'P-31', 'P-32', 'T-33', 'C-34', 'Fish-35', 'W-36', 'Fish-37', 'W-38', 'BLBS-39', 'BLBS-40', 'Awkward-41', 'Awkward-42', 'P-43', 'P-44', 'T-45', 'C-46', 'L-47', 'L-48', 'L-49', 'L-50', 'I-51', 'I-52', 'L-53', 'L-54', 'I-55', 'I-56', 'CO-57'];

    function getOLLScramble(type, length, cases) {
        var ollcase = oll_map[scrMgr.fixCase(cases, ollprobs)];
        return getAnyScramble(0xba987654ffff, ollcase[0], 0x7654ffff, ollcase[1], aufsuff, aufsuff);
    }

    function getEOLineScramble() {
        return getAnyScramble(0xffff7f5fffff, 0x000000000000, 0xffffffff, 0xffffffff);
    }

    function getEasyCrossScramble(type, length) {
        var cases = cross.getEasyCross(length);
        return getAnyScramble(cases[0], cases[1], 0xffffffff, 0xffffffff);
    }

    function genFacelet(facelet) {
        return search.solution(facelet, 21, 1e9, 50, 2);
    }

    function solvFacelet(facelet) {
        return search.solution(facelet, 21, 1e9, 50, 0);
    }

    scrMgr.reg('333', getRandomScramble)
        ('333fm', getFMCScramble)
        ('edges', getEdgeScramble)
        ('corners', getCornerScramble)
        ('ll', getLLScramble)
        ('lsll2', getLSLLScramble, [f2lfilter, f2lprobs])
        ('f2l', getF2LScramble)
        ('zbll', getZBLLScramble, [zbfilter, zbprobs])
        ('zzll', getZZLLScramble)
        ('zbls', getZBLSScramble)
        ('lse', getLSEScramble)
        ('cmll', getCMLLScramble, [cmfilter, cmprobs])
        ('cll', getCLLScramble)
        ('ell', getELLScramble)
        ('pll', getPLLScramble, [pllfilter, pllprobs])
        ('oll', getOLLScramble, [ollfilter, ollprobs])
        ('2gll', get2GLLScramble)
        ('easyc', getEasyCrossScramble)
        ('eoline', getEOLineScramble);

    return {
        /* mark2 interface */
        getRandomScramble: getRandomScramble, //getRandomScramble,

        /* added methods */
        getEdgeScramble: getEdgeScramble,
        getCornerScramble: getCornerScramble,
        getLLScramble: getLLScramble,
        getLSLLScramble: getLSLLScramble,
        getZBLLScramble: getZBLLScramble,
        getZZLLScramble: getZZLLScramble,
        getF2LScramble: getF2LScramble,
        getLSEScramble: getLSEScramble,
        getCMLLScramble: getCMLLScramble,
        getCLLScramble: getCLLScramble,
        getELLScramble: getELLScramble,
        getAnyScramble: getAnyScramble,
        genFacelet: genFacelet,
        solvFacelet: solvFacelet
    };

})(mathlib.getNPerm, mathlib.setNPerm, mathlib.set8Perm, mathlib.getNParity, mathlib.rn, mathlib.rndEl);


var scramble_444 = (function(rn, Cnk, circle) {

  
  var _, seedTable = {};
  var CM$ = {};
  var Q$Object = 0,
    Q$Serializable = 30,
    Q$Center1 = 21,
    Q$CornerCube = 22,
    Q$Edge3 = 23,
    Q$FullCube_0 = 24,
    Q$FullCube_$1 = 25,
    Q$Comparable = 34,
    Q$Search_0 = 26,
    Q$Object_$1 = 40;

                    
    function createArray(length1, length2)
    {
      var result, i;
      result = new Array(length1);
      if (length2 != undefined) {
        
          result[i] = new Array(length2);

      }
      return result;
    }
  function newSeed(id) {
    return new seedTable[id];
  }

  function defineSeed(id, superSeed, castableTypeMap) {
    var seed = seedTable[id];
    if (seed && !seed.___clazz$) {
      _ = seed.prototype;
    } else {
      !seed && (seed = seedTable[id] = function() {});
      _ = seed.prototype = superSeed < 0 ? {} : newSeed(superSeed);
      _.castableTypeMap$ = castableTypeMap;
    }
    for (var i_0 = 3; i_0 < arguments.length; ++i_0) {
      arguments[i_0].prototype = _;
    }
    if (seed.___clazz$) {
      _.___clazz$ = seed.___clazz$;
      seed.___clazz$ = null;
    }
  }

  function makeCastMap(a) {
    var result = {};
    for (var i_0 = 0, c = a.length; i_0 < c; ++i_0) {
      result[a[i_0]] = 1;
    }
    return result;
  }

  function nullMethod() {}

  defineSeed(1, -1, CM$);

  _.value = null;

  function Array_0() {}

  function createFrom(array, length_0) {
    var a, result;
    a = array;
    result = createFromSeed(0, length_0);
    initValues(a.___clazz$, a.castableTypeMap$, a.queryId$, result);
    return result;
  }

  function createFromSeed(seedType, length_0) {
    var array = new Array(length_0);
    if (seedType == 3) {
      for (var i_0 = 0; i_0 < length_0; ++i_0) {
        var value = new Object;
        value.l = value.m = value.h = 0;
        array[i_0] = value;
      }
    } else if (seedType > 0) {
      var value = [null, 0, false][seedType];
      for (var i_0 = 0; i_0 < length_0; ++i_0) {
        array[i_0] = value;
      }
    }
    return array;
  }

  function initDim(arrayClass, castableTypeMap, queryId, length_0, seedType) {
    var result;
    result = createFromSeed(seedType, length_0);
    initValues(arrayClass, castableTypeMap, queryId, result);
    return result;
  }

  function initValues(arrayClass, castableTypeMap, queryId, array) {
    $clinit_Array$ExpandoWrapper();
    wrapArray(array, expandoNames_0, expandoValues_0);
    array.___clazz$ = arrayClass;
    array.castableTypeMap$ = castableTypeMap;
    array.queryId$ = queryId;
    return array;
  }

  function setCheck(array, index, value) {
    return array[index] = value;
  }

  defineSeed(73, 1, {}, Array_0);
  _.queryId$ = 0;

  function $clinit_Array$ExpandoWrapper() {
    $clinit_Array$ExpandoWrapper = nullMethod;
    expandoNames_0 = [];
    expandoValues_0 = [];
    initExpandos(new Array_0, expandoNames_0, expandoValues_0);
  }

  function initExpandos(protoType, expandoNames, expandoValues) {
    var i_0 = 0,
      value;
    for (var name_0 in protoType) {
      if (value = protoType[name_0]) {
        expandoNames[i_0] = name_0;
        expandoValues[i_0] = value;
        ++i_0;
      }
    }
  }

  function wrapArray(array, expandoNames, expandoValues) {
    $clinit_Array$ExpandoWrapper();
    for (var i_0 = 0, c = expandoNames.length; i_0 < c; ++i_0) {
      array[expandoNames[i_0]] = expandoValues[i_0];
    }
  }

  var expandoNames_0, expandoValues_0;

  function canCast(src, dstId) {
    return src.castableTypeMap$ && !!src.castableTypeMap$[dstId];
  }

  function canCastUnsafe(src, dstId) {
    return src.castableTypeMap$ && src.castableTypeMap$[dstId];
  }

  function instanceOf(src, dstId) {
    return src != null && canCast(src, dstId);
  }

  function $clinit_Center1() {
    $clinit_Center1 = nullMethod;
    ctsmv = createArray(15582, 36);
    sym2raw = createArray(15582);
    csprun = createArray(15582);
    symmult = createArray(48, 48);
    symmove = createArray(48, 36);
    syminv = createArray(48);
    finish_0 = createArray(48);
  }

  function $$init_1(this$static) {
    this$static.ct = createArray(24);
  }

  function $equals(this$static, obj) {
    var c, i_0;
    if (instanceOf(obj, Q$Center1)) {
      c = obj;
      for (i_0 = 0; i_0 < 24; ++i_0) {
        if (this$static.ct[i_0] != c.ct[i_0]) {
          return false;
        }
      }
      return true;
    }
    return false;
  }

  function $get_1(this$static) {
    var i_0, idx, r;
    idx = 0;
    r = 8;
    for (i_0 = 23; i_0 >= 0; --i_0) {
      this$static.ct[i_0] == 1 && (idx += Cnk[i_0][r--]);
    }
    return idx;
  }

  function $getsym(this$static) {
    var cord, j;
    if (raw2sym != null) {
      return raw2sym[$get_1(this$static)];
    }
    for (j = 0; j < 48; ++j) {
      cord = raw2sym_0($get_1(this$static));
      if (cord != -1)
        return cord * 64 + j;
      $rot(this$static, 0);
      j % 2 == 1 && $rot(this$static, 1);
      j % 8 == 7 && $rot(this$static, 2);
      j % 16 == 15 && $rot(this$static, 3);
    }
  }

  function $move(this$static, m_0) {
    var key;
    key = m_0 % 3;
    m_0 = ~~(m_0 / 3);
    switch (m_0) {
      case 0:
        swap(this$static.ct, 0, 1, 2, 3, key);
        break;
      case 1:
        swap(this$static.ct, 16, 17, 18, 19, key);
        break;
      case 2:
        swap(this$static.ct, 8, 9, 10, 11, key);
        break;
      case 3:
        swap(this$static.ct, 4, 5, 6, 7, key);
        break;
      case 4:
        swap(this$static.ct, 20, 21, 22, 23, key);
        break;
      case 5:
        swap(this$static.ct, 12, 13, 14, 15, key);
        break;
      case 6:
        swap(this$static.ct, 0, 1, 2, 3, key);
        swap(this$static.ct, 8, 20, 12, 16, key);
        swap(this$static.ct, 9, 21, 13, 17, key);
        break;
      case 7:
        swap(this$static.ct, 16, 17, 18, 19, key);
        swap(this$static.ct, 1, 15, 5, 9, key);
        swap(this$static.ct, 2, 12, 6, 10, key);
        break;
      case 8:
        swap(this$static.ct, 8, 9, 10, 11, key);
        swap(this$static.ct, 2, 19, 4, 21, key);
        swap(this$static.ct, 3, 16, 5, 22, key);
        break;
      case 9:
        swap(this$static.ct, 4, 5, 6, 7, key);
        swap(this$static.ct, 10, 18, 14, 22, key);
        swap(this$static.ct, 11, 19, 15, 23, key);
        break;
      case 10:
        swap(this$static.ct, 20, 21, 22, 23, key);
        swap(this$static.ct, 0, 8, 4, 14, key);
        swap(this$static.ct, 3, 11, 7, 13, key);
        break;
      case 11:
        swap(this$static.ct, 12, 13, 14, 15, key);
        swap(this$static.ct, 1, 20, 7, 18, key);
        swap(this$static.ct, 0, 23, 6, 17, key);
    }
  }

  function $rot(this$static, r) {
    switch (r) {
      case 0:
        $move(this$static, 19);
        $move(this$static, 28);
        break;
      case 1:
        $move(this$static, 21);
        $move(this$static, 32);
        break;
      case 2:
        swap(this$static.ct, 0, 3, 1, 2, 1);
        swap(this$static.ct, 8, 11, 9, 10, 1);
        swap(this$static.ct, 4, 7, 5, 6, 1);
        swap(this$static.ct, 12, 15, 13, 14, 1);
        swap(this$static.ct, 16, 19, 21, 22, 1);
        swap(this$static.ct, 17, 18, 20, 23, 1);
        break;
      case 3:
        $move(this$static, 18);
        $move(this$static, 29);
        $move(this$static, 24);
        $move(this$static, 35);
    }
  }

  function $rotate(this$static, r) {
    var j;
    for (j = 0; j < r; ++j) {
      $rot(this$static, 0);
      j % 2 == 1 && $rot(this$static, 1);
      j % 8 == 7 && $rot(this$static, 2);
      j % 16 == 15 && $rot(this$static, 3);
    }
  }

  function $set_0(this$static, idx) {
    var i_0, r;
    r = 8;
    for (i_0 = 23; i_0 >= 0; --i_0) {
      this$static.ct[i_0] = 0;
      if (idx >= Cnk[i_0][r]) {
        idx -= Cnk[i_0][r--];
        this$static.ct[i_0] = 1;
      }
    }
  }

  function $set_1(this$static, c) {
    var i_0;
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this$static.ct[i_0] = c.ct[i_0];
    }
  }

  function Center1_0() {
    var i_0;
    $$init_1(this);
    for (i_0 = 0; i_0 < 8; ++i_0) {
      this.ct[i_0] = 1;
    }
    for (i_0 = 8; i_0 < 24; ++i_0) {
      this.ct[i_0] = 0;
    }
  }

  function Center1_1(c, urf) {
    var i_0;
    $$init_1(this);
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this.ct[i_0] = (~~(c.ct[i_0] / 2) == urf ? 1 : 0);
    }
  }

  function Center1_2(ct) {
    var i_0;
    $$init_1(this);
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this.ct[i_0] = ct[i_0];
    }
  }

  function createMoveTable() {
    var c, d, i_0, m_0;
    c = new Center1_0;
    d = new Center1_0;
    for (i_0 = 0; i_0 < 15582; ++i_0) {
      $set_0(d, sym2raw[i_0]);
      for (m_0 = 0; m_0 < 36; ++m_0) {
        $set_1(c, d);
        $move(c, m_0);
        ctsmv[i_0][m_0] = $getsym(c);
      }
    }
  }

  function createPrun() {
    var check, depth, done, i_0, idx, inv, m_0, select;
    fill_0(csprun);
    csprun[0] = 0;
    depth = 0;
    done = 1;
    while (done != 15582) {
      inv = depth > 4;
      select = inv ? -1 : depth;
      check = inv ? depth : -1;
      ++depth;
      for (i_0 = 0; i_0 < 15582; ++i_0) {
        if (csprun[i_0] != select) {
          continue;
        }
        for (m_0 = 0; m_0 < 27; ++m_0) {
          idx = ~~ctsmv[i_0][m_0] >>> 6;
          if (csprun[idx] != check) {
            continue;
          }
          ++done;
          if (inv) {
            csprun[i_0] = depth;
            break;
          } else {
            csprun[idx] = depth;
          }
        }
      }
    }
  }

  function getSolvedSym(cube) {
    var c, check, i_0, j;
    c = new Center1_2(cube.ct);
    for (j = 0; j < 48; ++j) {
      check = true;
      for (i_0 = 0; i_0 < 24; ++i_0) {
        if (c.ct[i_0] != ~~(i_0 / 4)) {
          check = false;
          break;
        }
      }
      if (check) {
        return j;
      }
      $rot(c, 0);
      j % 2 == 1 && $rot(c, 1);
      j % 8 == 7 && $rot(c, 2);
      j % 16 == 15 && $rot(c, 3);
    }
    return -1;
  }

  function initSym_0() {
    var c, d, e, f, i_0, j, k_0;
    c = new Center1_0;
    for (i_0 = 0; i_0 < 24; ++i_0) {
      c.ct[i_0] = i_0;
    }
    d = new Center1_2(c.ct);
    e = new Center1_2(c.ct);
    f = new Center1_2(c.ct);
    for (i_0 = 0; i_0 < 48; ++i_0) {
      for (j = 0; j < 48; ++j) {
        for (k_0 = 0; k_0 < 48; ++k_0) {
          if ($equals(c, d)) {
            symmult[i_0][j] = k_0;
            k_0 == 0 && (syminv[i_0] = j);
          }
          $rot(d, 0);
          k_0 % 2 == 1 && $rot(d, 1);
          k_0 % 8 == 7 && $rot(d, 2);
          k_0 % 16 == 15 && $rot(d, 3);
        }
        $rot(c, 0);
        j % 2 == 1 && $rot(c, 1);
        j % 8 == 7 && $rot(c, 2);
        j % 16 == 15 && $rot(c, 3);
      }
      $rot(c, 0);
      i_0 % 2 == 1 && $rot(c, 1);
      i_0 % 8 == 7 && $rot(c, 2);
      i_0 % 16 == 15 && $rot(c, 3);
    }
    for (i_0 = 0; i_0 < 48; ++i_0) {
      $set_1(c, e);
      $rotate(c, syminv[i_0]);
      for (j = 0; j < 36; ++j) {
        $set_1(d, c);
        $move(d, j);
        $rotate(d, i_0);
        for (k_0 = 0; k_0 < 36; ++k_0) {
          $set_1(f, e);
          $move(f, k_0);
          if ($equals(f, d)) {
            symmove[i_0][j] = k_0;
            break;
          }
        }
      }
    }
    $set_0(c, 0);
    for (i_0 = 0; i_0 < 48; ++i_0) {
      finish_0[syminv[i_0]] = $get_1(c);
      $rot(c, 0);
      i_0 % 2 == 1 && $rot(c, 1);
      i_0 % 8 == 7 && $rot(c, 2);
      i_0 % 16 == 15 && $rot(c, 3);
    }
  }

  function initSym2Raw() {
    var c, count, i_0, idx, j, occ;
    c = new Center1_0;
    occ = createArray(22984);
    for (i_0 = 0; i_0 < 22984; i_0++) {
      occ[i_0] = 0;
    }
    count = 0;
    for (i_0 = 0; i_0 < 735471; ++i_0) {
      if ((occ[~~i_0 >>> 5] & 1 << (i_0 & 31)) == 0) {
        $set_0(c, i_0);
        for (j = 0; j < 48; ++j) {
          idx = $get_1(c);
          occ[~~idx >>> 5] |= 1 << (idx & 31);
          raw2sym != null && (raw2sym[idx] = count << 6 | syminv[j]);
          $rot(c, 0);
          j % 2 == 1 && $rot(c, 1);
          j % 8 == 7 && $rot(c, 2);
          j % 16 == 15 && $rot(c, 3);
        }
        sym2raw[count++] = i_0;
      }
    }
  }

  function raw2sym_0(n) {
    var m_0;
    m_0 = binarySearch_0(sym2raw, n);
    return m_0 >= 0 ? m_0 : -1;
  }

  defineSeed(153, 1, makeCastMap([Q$Center1]), Center1_0, Center1_1, Center1_2);

  var csprun, ctsmv, finish_0, raw2sym = null,
    sym2raw, syminv, symmove, symmult;

  function $clinit_Center2() {
    $clinit_Center2 = nullMethod;
    rlmv = createArray(70, 28);
    ctmv = createArray(6435, 28);
    rlrot = createArray(70, 16);
    ctrot = createArray(6435, 16);
    ctprun = createArray(450450);
    pmv = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0, 0, 0, 0, 1, 0, 1, 0, 0, 0];
  }

  function $getct(this$static) {
    var i_0, idx, r;
    idx = 0;
    r = 8;
    for (i_0 = 14; i_0 >= 0; --i_0) {
      this$static.ct[i_0] != this$static.ct[15] && (idx += Cnk[i_0][r--]);
    }
    return idx;
  }

  function $getrl(this$static) {
    var i_0, idx, r;
    idx = 0;
    r = 4;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      this$static.rl[i_0] != this$static.rl[7] && (idx += Cnk[i_0][r--]);
    }
    return idx * 2 + this$static.parity;
  }

  function $move_0(this$static, m_0) {
    var key;
    this$static.parity ^= pmv[m_0];
    key = m_0 % 3;
    m_0 = ~~(m_0 / 3);
    switch (m_0) {
      case 0:
        swap(this$static.ct, 0, 1, 2, 3, key);
        break;
      case 1:
        swap(this$static.rl, 0, 1, 2, 3, key);
        break;
      case 2:
        swap(this$static.ct, 8, 9, 10, 11, key);
        break;
      case 3:
        swap(this$static.ct, 4, 5, 6, 7, key);
        break;
      case 4:
        swap(this$static.rl, 4, 5, 6, 7, key);
        break;
      case 5:
        swap(this$static.ct, 12, 13, 14, 15, key);
        break;
      case 6:
        swap(this$static.ct, 0, 1, 2, 3, key);
        swap(this$static.rl, 0, 5, 4, 1, key);
        swap(this$static.ct, 8, 9, 12, 13, key);
        break;
      case 7:
        swap(this$static.rl, 0, 1, 2, 3, key);
        swap(this$static.ct, 1, 15, 5, 9, key);
        swap(this$static.ct, 2, 12, 6, 10, key);
        break;
      case 8:
        swap(this$static.ct, 8, 9, 10, 11, key);
        swap(this$static.rl, 0, 3, 6, 5, key);
        swap(this$static.ct, 3, 2, 5, 4, key);
        break;
      case 9:
        swap(this$static.ct, 4, 5, 6, 7, key);
        swap(this$static.rl, 3, 2, 7, 6, key);
        swap(this$static.ct, 11, 10, 15, 14, key);
        break;
      case 10:
        swap(this$static.rl, 4, 5, 6, 7, key);
        swap(this$static.ct, 0, 8, 4, 14, key);
        swap(this$static.ct, 3, 11, 7, 13, key);
        break;
      case 11:
        swap(this$static.ct, 12, 13, 14, 15, key);
        swap(this$static.rl, 1, 4, 7, 2, key);
        swap(this$static.ct, 1, 0, 7, 6, key);
    }
  }

  function $rot_0(this$static, r) {
    switch (r) {
      case 0:
        $move_0(this$static, 19);
        $move_0(this$static, 28);
        break;
      case 1:
        $move_0(this$static, 21);
        $move_0(this$static, 32);
        break;
      case 2:
        swap(this$static.ct, 0, 3, 1, 2, 1);
        swap(this$static.ct, 8, 11, 9, 10, 1);
        swap(this$static.ct, 4, 7, 5, 6, 1);
        swap(this$static.ct, 12, 15, 13, 14, 1);
        swap(this$static.rl, 0, 3, 5, 6, 1);
        swap(this$static.rl, 1, 2, 4, 7, 1);
    }
  }

  function $set_2(this$static, c, edgeParity) {
    var i_0;
    for (i_0 = 0; i_0 < 16; ++i_0) {
      this$static.ct[i_0] = ~~(c.ct[i_0] / 2);
    }
    for (i_0 = 0; i_0 < 8; ++i_0) {
      this$static.rl[i_0] = c.ct[i_0 + 16];
    }
    this$static.parity = edgeParity;
  }

  function $setct(this$static, idx) {
    var i_0, r;
    r = 8;
    this$static.ct[15] = 0;
    for (i_0 = 14; i_0 >= 0; --i_0) {
      if (idx >= Cnk[i_0][r]) {
        idx -= Cnk[i_0][r--];
        this$static.ct[i_0] = 1;
      } else {
        this$static.ct[i_0] = 0;
      }
    }
  }

  function $setrl(this$static, idx) {
    var i_0, r;
    this$static.parity = idx & 1;
    idx >>>= 1;
    r = 4;
    this$static.rl[7] = 0;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      if (idx >= Cnk[i_0][r]) {
        idx -= Cnk[i_0][r--];
        this$static.rl[i_0] = 1;
      } else {
        this$static.rl[i_0] = 0;
      }
    }
  }

  function Center2_0() {
    this.rl = createArray(8);
    this.ct = createArray(16);
  }

  function init_3() {
    var c, ct, ctx, depth, done, i_0, idx, j, m_0, rl, rlx;
    c = new Center2_0;
    for (i_0 = 0; i_0 < 70; ++i_0) {
      for (m_0 = 0; m_0 < 28; ++m_0) {
        $setrl(c, i_0);
        $move_0(c, move2std[m_0]);
        rlmv[i_0][m_0] = $getrl(c);
      }
    }
    for (i_0 = 0; i_0 < 70; ++i_0) {
      $setrl(c, i_0);
      for (j = 0; j < 16; ++j) {
        rlrot[i_0][j] = $getrl(c);
        $rot_0(c, 0);
        j % 2 == 1 && $rot_0(c, 1);
        j % 8 == 7 && $rot_0(c, 2);
      }
    }
    for (i_0 = 0; i_0 < 6435; ++i_0) {
      $setct(c, i_0);
      for (j = 0; j < 16; ++j) {
        ctrot[i_0][j] = $getct(c) & 65535;
        $rot_0(c, 0);
        j % 2 == 1 && $rot_0(c, 1);
        j % 8 == 7 && $rot_0(c, 2);
      }
    }
    for (i_0 = 0; i_0 < 6435; ++i_0) {
      for (m_0 = 0; m_0 < 28; ++m_0) {
        $setct(c, i_0);
        $move_0(c, move2std[m_0]);
        ctmv[i_0][m_0] = $getct(c) & 65535;
      }
    }
    fill_0(ctprun);
    ctprun[0] = ctprun[18] = ctprun[28] = ctprun[46] = ctprun[54] = ctprun[56] = 0;
    depth = 0;
    done = 6;

    while (done != 450450) {
      var inv = depth > 6;
      var select = inv ? -1 : depth;
      var check = inv ? depth : -1;
      ++depth;
      for (i_0 = 0; i_0 < 450450; ++i_0) {
        if (ctprun[i_0] != select) {
          continue;
        }
        ct = ~~(i_0 / 70);
        rl = i_0 % 70;
        for (m_0 = 0; m_0 < 23; ++m_0) {
          ctx = ctmv[ct][m_0];
          rlx = rlmv[rl][m_0];
          idx = ctx * 70 + rlx;
          if (ctprun[idx] != check) {
            continue;
          }
          ++done;
          if (inv) {
            ctprun[i_0] = depth;
            break;
          } else {
            ctprun[idx] = depth;
          }
        }
      }
    }
  }

  defineSeed(154, 1, {}, Center2_0);
  _.parity = 0;
  var ctmv, ctprun, ctrot, pmv, rlmv, rlrot;

  function $clinit_Center3() {
    $clinit_Center3 = nullMethod;
    ctmove = createArray(29400, 20);
    pmove = [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 1, 1, 1, 1, 1];
    prun_0 = createArray(29400);
    rl2std = [0, 9, 14, 23, 27, 28, 41, 42, 46, 55, 60, 69];
    std2rl = createArray(70);
  }

  function $getct_0(this$static) {
    var check, i_0, idx, idxrl, r;
    idx = 0;
    r = 4;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      this$static.ud[i_0] != this$static.ud[7] && (idx += Cnk[i_0][r--]);
    }
    idx *= 35;
    r = 4;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      this$static.fb[i_0] != this$static.fb[7] && (idx += Cnk[i_0][r--]);
    }
    idx *= 12;
    check = this$static.fb[7] ^ this$static.ud[7];
    idxrl = 0;
    r = 4;
    for (i_0 = 7; i_0 >= 0; --i_0) {
      this$static.rl[i_0] != check && (idxrl += Cnk[i_0][r--]);
    }
    return this$static.parity + 2 * (idx + std2rl[idxrl]);
  }

  function $move_1(this$static, i_0) {
    this$static.parity ^= pmove[i_0];
    switch (i_0) {
      case 0:
      case 1:
      case 2:
        swap(this$static.ud, 0, 1, 2, 3, i_0 % 3);
        break;
      case 3:
        swap(this$static.rl, 0, 1, 2, 3, 1);
        break;
      case 4:
      case 5:
      case 6:
        swap(this$static.fb, 0, 1, 2, 3, (i_0 - 1) % 3);
        break;
      case 7:
      case 8:
      case 9:
        swap(this$static.ud, 4, 5, 6, 7, (i_0 - 1) % 3);
        break;
      case 10:
        swap(this$static.rl, 4, 5, 6, 7, 1);
        break;
      case 11:
      case 12:
      case 13:
        swap(this$static.fb, 4, 5, 6, 7, (i_0 + 1) % 3);
        break;
      case 14:
        swap(this$static.ud, 0, 1, 2, 3, 1);
        swap(this$static.rl, 0, 5, 4, 1, 1);
        swap(this$static.fb, 0, 5, 4, 1, 1);
        break;
      case 15:
        swap(this$static.rl, 0, 1, 2, 3, 1);
        swap(this$static.fb, 1, 4, 7, 2, 1);
        swap(this$static.ud, 1, 6, 5, 2, 1);
        break;
      case 16:
        swap(this$static.fb, 0, 1, 2, 3, 1);
        swap(this$static.ud, 3, 2, 5, 4, 1);
        swap(this$static.rl, 0, 3, 6, 5, 1);
        break;
      case 17:
        swap(this$static.ud, 4, 5, 6, 7, 1);
        swap(this$static.rl, 3, 2, 7, 6, 1);
        swap(this$static.fb, 3, 2, 7, 6, 1);
        break;
      case 18:
        swap(this$static.rl, 4, 5, 6, 7, 1);
        swap(this$static.fb, 0, 3, 6, 5, 1);
        swap(this$static.ud, 0, 3, 4, 7, 1);
        break;
      case 19:
        swap(this$static.fb, 4, 5, 6, 7, 1);
        swap(this$static.ud, 0, 7, 6, 1, 1);
        swap(this$static.rl, 1, 4, 7, 2, 1);
    }
  }

  function $set_3(this$static, c, eXc_parity) {
    var i_0, parity;
    parity = c.ct[0] > c.ct[8] ^ c.ct[8] > c.ct[16] ^ c.ct[0] > c.ct[16] ? 1 : 0;
    for (i_0 = 0; i_0 < 8; ++i_0) {
      this$static.ud[i_0] = c.ct[i_0] & 1 ^ 1;
      this$static.fb[i_0] = c.ct[i_0 + 8] & 1 ^ 1;
      this$static.rl[i_0] = c.ct[i_0 + 16] & 1 ^ 1 ^ parity;
    }
    this$static.parity = parity ^ eXc_parity;
  }

  function $setct_0(this$static, idx) {
    var i_0, idxfb, idxrl, r;
    this$static.parity = idx & 1;
    idx >>>= 1;
    idxrl = rl2std[idx % 12];
    idx = ~~(idx / 12);
    r = 4;
    for (i_0 = 7; i_0 >= 0; --i_0) {
      this$static.rl[i_0] = 0;
      if (idxrl >= Cnk[i_0][r]) {
        idxrl -= Cnk[i_0][r--];
        this$static.rl[i_0] = 1;
      }
    }
    idxfb = idx % 35;
    idx = ~~(idx / 35);
    r = 4;
    this$static.fb[7] = 0;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      if (idxfb >= Cnk[i_0][r]) {
        idxfb -= Cnk[i_0][r--];
        this$static.fb[i_0] = 1;
      } else {
        this$static.fb[i_0] = 0;
      }
    }
    r = 4;
    this$static.ud[7] = 0;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      if (idx >= Cnk[i_0][r]) {
        idx -= Cnk[i_0][r--];
        this$static.ud[i_0] = 1;
      } else {
        this$static.ud[i_0] = 0;
      }
    }
  }

  function Center3_0() {
    this.ud = createArray(8);
    this.rl = createArray(8);
    this.fb = createArray(8);
  }

  function init_4() {
    var c, depth, done, i_0, m_0;
    for (i_0 = 0; i_0 < 12; ++i_0) {
      std2rl[rl2std[i_0]] = i_0;
    }
    c = new Center3_0;
    for (i_0 = 0; i_0 < 29400; ++i_0) {
      for (m_0 = 0; m_0 < 20; ++m_0) {
        $setct_0(c, i_0);
        $move_1(c, m_0);
        ctmove[i_0][m_0] = $getct_0(c) & 65535;
      }
    }
    fill_0(prun_0);
    prun_0[0] = 0;
    depth = 0;
    done = 1;
    while (done != 29400) {
      for (i_0 = 0; i_0 < 29400; ++i_0) {
        if (prun_0[i_0] != depth) {
          continue;
        }
        for (m_0 = 0; m_0 < 17; ++m_0) {
          if (prun_0[ctmove[i_0][m_0]] == -1) {
            prun_0[ctmove[i_0][m_0]] = depth + 1;
            ++done;
          }
        }
      }
      ++depth;
    }
  }

  defineSeed(155, 1, {}, Center3_0);
  _.parity = 0;
  var ctmove, pmove, prun_0, rl2std, std2rl;

  function $clinit_CenterCube() {
    $clinit_CenterCube = nullMethod;
    center333Map = [0, 4, 2, 1, 5, 3];
  }

  function $copy_1(this$static, c) {
    var i_0;
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this$static.ct[i_0] = c.ct[i_0];
    }
  }

  function $move_2(this$static, m_0) {
    var key;
    key = m_0 % 3;
    m_0 = ~~(m_0 / 3);
    switch (m_0) {
      case 0:
        swap(this$static.ct, 0, 1, 2, 3, key);
        break;
      case 1:
        swap(this$static.ct, 16, 17, 18, 19, key);
        break;
      case 2:
        swap(this$static.ct, 8, 9, 10, 11, key);
        break;
      case 3:
        swap(this$static.ct, 4, 5, 6, 7, key);
        break;
      case 4:
        swap(this$static.ct, 20, 21, 22, 23, key);
        break;
      case 5:
        swap(this$static.ct, 12, 13, 14, 15, key);
        break;
      case 6:
        swap(this$static.ct, 0, 1, 2, 3, key);
        swap(this$static.ct, 8, 20, 12, 16, key);
        swap(this$static.ct, 9, 21, 13, 17, key);
        break;
      case 7:
        swap(this$static.ct, 16, 17, 18, 19, key);
        swap(this$static.ct, 1, 15, 5, 9, key);
        swap(this$static.ct, 2, 12, 6, 10, key);
        break;
      case 8:
        swap(this$static.ct, 8, 9, 10, 11, key);
        swap(this$static.ct, 2, 19, 4, 21, key);
        swap(this$static.ct, 3, 16, 5, 22, key);
        break;
      case 9:
        swap(this$static.ct, 4, 5, 6, 7, key);
        swap(this$static.ct, 10, 18, 14, 22, key);
        swap(this$static.ct, 11, 19, 15, 23, key);
        break;
      case 10:
        swap(this$static.ct, 20, 21, 22, 23, key);
        swap(this$static.ct, 0, 8, 4, 14, key);
        swap(this$static.ct, 3, 11, 7, 13, key);
        break;
      case 11:
        swap(this$static.ct, 12, 13, 14, 15, key);
        swap(this$static.ct, 1, 20, 7, 18, key);
        swap(this$static.ct, 0, 23, 6, 17, key);
    }
  }

  function CenterCube_0() {
    var i_0;
    this.ct = createArray(24);
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this.ct[i_0] = ~~(i_0 / 4);
    }
  }

  function CenterCube_1(r) {
    var i_0, m_0, t;
    CenterCube_0.call(this);
    for (i_0 = 0; i_0 < 23; ++i_0) {
      t = i_0 + rn(24 - i_0);
      if (this.ct[t] != this.ct[i_0]) {
        m_0 = this.ct[i_0];
        this.ct[i_0] = this.ct[t];
        this.ct[t] = m_0;
      }
    }
  }

  defineSeed(156, 1, {}, CenterCube_0, CenterCube_1);
  var center333Map;

  function $clinit_CornerCube() {
    $clinit_CornerCube = nullMethod;
    moveCube_0 = createArray(18);
    cornerFacelet_0 = [
      [8, 9, 20],
      [6, 18, 38],
      [0, 36, 47],
      [2, 45, 11],
      [29, 26, 15],
      [27, 44, 24],
      [33, 53, 42],
      [35, 17, 51]
    ];
    initMove_0();
  }

  function $$init_2(this$static) {
    this$static.cp = [0, 1, 2, 3, 4, 5, 6, 7];
    this$static.co = [0, 0, 0, 0, 0, 0, 0, 0];
  }

  function $copy_2(this$static, c) {
    var i_0;
    for (i_0 = 0; i_0 < 8; ++i_0) {
      this$static.cp[i_0] = c.cp[i_0];
      this$static.co[i_0] = c.co[i_0];
    }
  }

  function $move_3(this$static, idx) {
    !this$static.temps && (this$static.temps = new CornerCube_0);
    CornMult_0(this$static, moveCube_0[idx], this$static.temps);
    $copy_2(this$static, this$static.temps);
  }

  function $setTwist_0(this$static, idx) {
    var i_0, twst;
    twst = 0;
    for (i_0 = 6; i_0 >= 0; --i_0) {
      twst += this$static.co[i_0] = idx % 3;
      idx = ~~(idx / 3);
    }
    this$static.co[7] = (15 - twst) % 3;
  }

  function CornMult_0(a, b, prod) {
    var corn, ori, oriA, oriB;
    for (corn = 0; corn < 8; ++corn) {
      prod.cp[corn] = a.cp[b.cp[corn]];
      oriA = a.co[b.cp[corn]];
      oriB = b.co[corn];
      ori = oriA;
      ori = ori + (oriA < 3 ? oriB : 6 - oriB);
      ori = ori % 3;
      oriA >= 3 ^ oriB >= 3 && (ori = ori + 3);
      prod.co[corn] = ori;
    }
  }

  function CornerCube_0() {
    $$init_2(this);
  }

  function CornerCube_1(cperm, twist) {
    $$init_2(this);
    mathlib.set8Perm(this.cp, cperm);
    $setTwist_0(this, twist);
  }

  function CornerCube_2(r) {
    CornerCube_1.call(this, rn(40320), rn(2187));
  }

  function initMove_0() {
    var a, p_0;
    moveCube_0[0] = new CornerCube_1(15120, 0);
    moveCube_0[3] = new CornerCube_1(21021, 1494);
    moveCube_0[6] = new CornerCube_1(8064, 1236);
    moveCube_0[9] = new CornerCube_1(9, 0);
    moveCube_0[12] = new CornerCube_1(1230, 412);
    moveCube_0[15] = new CornerCube_1(224, 137);
    for (a = 0; a < 18; a += 3) {
      for (p_0 = 0; p_0 < 2; ++p_0) {
        moveCube_0[a + p_0 + 1] = new CornerCube_0;
        CornMult_0(moveCube_0[a + p_0], moveCube_0[a], moveCube_0[a + p_0 + 1]);
      }
    }
  }

  defineSeed(157, 1, makeCastMap([Q$CornerCube]), CornerCube_0, CornerCube_1, CornerCube_2);
  _.temps = null;
  var cornerFacelet_0, moveCube_0;

  function $clinit_Edge3() {
    $clinit_Edge3 = nullMethod;
    prunValues = [1, 4, 16, 55, 324, 1922, 12275, 77640, 485359, 2778197, 11742425, 27492416, 31002941, 31006080];
    eprun = createArray(1937880);
    sym2raw_0 = createArray(1538);
    symstate = createArray(1538);
    raw2sym_1 = createArray(11880);
    syminv_0 = [0, 1, 6, 3, 4, 5, 2, 7];
    mvrot = createArray(160, 12);
    mvroto = createArray(160, 12);
    factX = [1, 1, 1, 3, 12, 60, 360, 2520, 20160, 181440, 1814400, 19958400, 239500800];
    FullEdgeMap = [0, 2, 4, 6, 1, 3, 7, 5, 8, 9, 10, 11];
  }

  function $circlex(this$static, a, b, c, d) {
    var temp;
    temp = this$static.edgeo[d];
    this$static.edgeo[d] = this$static.edge[c];
    this$static.edge[c] = this$static.edgeo[b];
    this$static.edgeo[b] = this$static.edge[a];
    this$static.edge[a] = temp;
  }

  function $get_2(this$static, end) {
    var i_0, idx, v, valh, vall;
    this$static.isStd || $std(this$static);
    idx = 0;
    vall = 1985229328;
    valh = 47768;
    for (i_0 = 0; i_0 < end; ++i_0) {
      v = this$static.edge[i_0] << 2;
      idx *= 12 - i_0;
      if (v >= 32) {
        idx += valh >> v - 32 & 15;
        valh -= 4368 << v - 32;
      } else {
        idx += vall >> v & 15;
        valh -= 4369;
        vall -= 286331152 << v;
      }
    }
    return idx;
  }

  function $getsym_0(this$static) {
    var cord1x, cord2x, symcord1x, symx;
    cord1x = $get_2(this$static, 4);
    symcord1x = raw2sym_1[cord1x];
    symx = symcord1x & 7;
    symcord1x >>= 3;
    $rotate_0(this$static, symx);
    cord2x = $get_2(this$static, 10) % 20160;
    return symcord1x * 20160 + cord2x;
  }

  function $move_4(this$static, i_0) {
    this$static.isStd = false;
    switch (i_0) {
      case 0:
        circle(this$static.edge, 0, 4, 1, 5);
        circle(this$static.edgeo, 0, 4, 1, 5);
        break;
      case 1:
        $swap_0(this$static.edge, 0, 4, 1, 5);
        $swap_0(this$static.edgeo, 0, 4, 1, 5);
        break;
      case 2:
        circle(this$static.edge, 0, 5, 1, 4);
        circle(this$static.edgeo, 0, 5, 1, 4);
        break;
      case 3:
        $swap_0(this$static.edge, 5, 10, 6, 11);
        $swap_0(this$static.edgeo, 5, 10, 6, 11);
        break;
      case 4:
        circle(this$static.edge, 0, 11, 3, 8);
        circle(this$static.edgeo, 0, 11, 3, 8);
        break;
      case 5:
        $swap_0(this$static.edge, 0, 11, 3, 8);
        $swap_0(this$static.edgeo, 0, 11, 3, 8);
        break;
      case 6:
        circle(this$static.edge, 0, 8, 3, 11);
        circle(this$static.edgeo, 0, 8, 3, 11);
        break;
      case 7:
        circle(this$static.edge, 2, 7, 3, 6);
        circle(this$static.edgeo, 2, 7, 3, 6);
        break;
      case 8:
        $swap_0(this$static.edge, 2, 7, 3, 6);
        $swap_0(this$static.edgeo, 2, 7, 3, 6);
        break;
      case 9:
        circle(this$static.edge, 2, 6, 3, 7);
        circle(this$static.edgeo, 2, 6, 3, 7);
        break;
      case 10:
        $swap_0(this$static.edge, 4, 8, 7, 9);
        $swap_0(this$static.edgeo, 4, 8, 7, 9);
        break;
      case 11:
        circle(this$static.edge, 1, 9, 2, 10);
        circle(this$static.edgeo, 1, 9, 2, 10);
        break;
      case 12:
        $swap_0(this$static.edge, 1, 9, 2, 10);
        $swap_0(this$static.edgeo, 1, 9, 2, 10);
        break;
      case 13:
        circle(this$static.edge, 1, 10, 2, 9);
        circle(this$static.edgeo, 1, 10, 2, 9);
        break;
      case 14:
        $swap_0(this$static.edge, 0, 4, 1, 5);
        $swap_0(this$static.edgeo, 0, 4, 1, 5);
        circle(this$static.edge, 9, 11);
        circle(this$static.edgeo, 8, 10);
        break;
      case 15:
        $swap_0(this$static.edge, 5, 10, 6, 11);
        $swap_0(this$static.edgeo, 5, 10, 6, 11);
        circle(this$static.edge, 1, 3);
        circle(this$static.edgeo, 0, 2);
        break;
      case 16:
        $swap_0(this$static.edge, 0, 11, 3, 8);
        $swap_0(this$static.edgeo, 0, 11, 3, 8);
        circle(this$static.edge, 5, 7);
        circle(this$static.edgeo, 4, 6);
        break;
      case 17:
        $swap_0(this$static.edge, 2, 7, 3, 6);
        $swap_0(this$static.edgeo, 2, 7, 3, 6);
        circle(this$static.edge, 8, 10);
        circle(this$static.edgeo, 9, 11);
        break;
      case 18:
        $swap_0(this$static.edge, 4, 8, 7, 9);
        $swap_0(this$static.edgeo, 4, 8, 7, 9);
        circle(this$static.edge, 0, 2);
        circle(this$static.edgeo, 1, 3);
        break;
      case 19:
        $swap_0(this$static.edge, 1, 9, 2, 10);
        $swap_0(this$static.edgeo, 1, 9, 2, 10);
        circle(this$static.edge, 4, 6);
        circle(this$static.edgeo, 5, 7);
    }
  }

  function $rot_1(this$static, r) {
    this$static.isStd = false;
    switch (r) {
      case 0:
        $move_4(this$static, 14);
        $move_4(this$static, 17);
        break;
      case 1:
        $circlex(this$static, 11, 5, 10, 6);
        $circlex(this$static, 5, 10, 6, 11);
        $circlex(this$static, 1, 2, 3, 0);
        $circlex(this$static, 4, 9, 7, 8);
        $circlex(this$static, 8, 4, 9, 7);
        $circlex(this$static, 0, 1, 2, 3);
        break;
      case 2:
        $swapx(this$static, 4, 5);
        $swapx(this$static, 5, 4);
        $swapx(this$static, 11, 8);
        $swapx(this$static, 8, 11);
        $swapx(this$static, 7, 6);
        $swapx(this$static, 6, 7);
        $swapx(this$static, 9, 10);
        $swapx(this$static, 10, 9);
        $swapx(this$static, 1, 1);
        $swapx(this$static, 0, 0);
        $swapx(this$static, 3, 3);
        $swapx(this$static, 2, 2);
    }
  }

  function $rotate_0(this$static, r) {
    while (r >= 2) {
      r -= 2;
      $rot_1(this$static, 1);
      $rot_1(this$static, 2);
    }
    r != 0 && $rot_1(this$static, 0);
  }

  function $set_4(this$static, idx) {
    var i_0, p_0, parity, v, vall, valh;
    vall = 0x76543210;
    valh = 0xba98;
    parity = 0;
    for (i_0 = 0; i_0 < 11; ++i_0) {
      p_0 = factX[11 - i_0];
      v = ~~(idx / p_0);
      idx = idx % p_0;
      parity ^= v;
      v <<= 2;
      if (v >= 32) {
        v = v - 32;
        this$static.edge[i_0] = valh >> v & 15;
        var m = (1 << v) - 1;
        valh = (valh & m) + ((valh >> 4) & ~m);
      } else {
        this$static.edge[i_0] = vall >> v & 15;
        var m = (1 << v) - 1;
        vall = (vall & m) + ((vall >>> 4) & ~m) + (valh << 28);
        valh = valh >> 4;
      }
    }
    if ((parity & 1) == 0) {
      this$static.edge[11] = vall;
    } else {
      this$static.edge[11] = this$static.edge[10];
      this$static.edge[10] = vall;
    }
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.edgeo[i_0] = i_0;
    }
    this$static.isStd = true;
  }

  function $set_5(this$static, e) {
    var i_0;
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.edge[i_0] = e.edge[i_0];
      this$static.edgeo[i_0] = e.edgeo[i_0];
    }
    this$static.isStd = e.isStd;
  }

  function $set_6(this$static, c) {
    var i_0, parity, s, t;
    this$static.temp == null && (this$static.temp = createArray(12));
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.temp[i_0] = i_0;
      this$static.edge[i_0] = c.ep[FullEdgeMap[i_0] + 12] % 12;
    }
    parity = 1;
    for (i_0 = 0; i_0 < 12; ++i_0) {
      while (this$static.edge[i_0] != i_0) {
        t = this$static.edge[i_0];
        this$static.edge[i_0] = this$static.edge[t];
        this$static.edge[t] = t;
        s = this$static.temp[i_0];
        this$static.temp[i_0] = this$static.temp[t];
        this$static.temp[t] = s;
        parity ^= 1;
      }
    }
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.edge[i_0] = this$static.temp[c.ep[FullEdgeMap[i_0]] % 12];
    }
    return parity;
  }

  function $std(this$static) {
    var i_0;
    this$static.temp == null && (this$static.temp = createArray(12));
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.temp[this$static.edgeo[i_0]] = i_0;
    }
    for (i_0 = 0; i_0 < 12; ++i_0) {
      this$static.edge[i_0] = this$static.temp[this$static.edge[i_0]];
      this$static.edgeo[i_0] = i_0;
    }
    this$static.isStd = true;
  }

  function $swap_0(arr, a, b, c, d) {
    var temp;
    temp = arr[a];
    arr[a] = arr[c];
    arr[c] = temp;
    temp = arr[b];
    arr[b] = arr[d];
    arr[d] = temp;
  }

  function $swapx(this$static, x, y) {
    var temp;
    temp = this$static.edge[x];
    this$static.edge[x] = this$static.edgeo[y];
    this$static.edgeo[y] = temp;
  }

  function Edge3_0() {
    this.edge = createArray(12);
    this.edgeo = createArray(12);
  }

  function createPrun_0() {
    var chk, cord1, cord1x, cord2, cord2x, dep1m3, depm3, depth, e, end, f, find_0, g, i_0, i_, idx, idxx, inv, j, m_0, symState, symcord1, symcord1x, symx, val;
    e = new Edge3_0;
    f = new Edge3_0;
    g = new Edge3_0;
    fill_0(eprun);
    depth = 0;
    done_0 = 1;
    setPruning_0(eprun, 0, 0);
    // var start = +new Date;
    while (done_0 != 31006080) {
      inv = depth > 9;
      depm3 = depth % 3;
      dep1m3 = (depth + 1) % 3;
      find_0 = inv ? 3 : depm3;
      chk = inv ? depm3 : 3;
      if (depth >= 9) {
        break;
      }
      for (i_ = 0; i_ < 31006080; i_ += 16) {
        val = eprun[~~i_ >> 4];
        if (!inv && val == -1) {
          continue;
        }
        for (i_0 = i_, end = i_ + 16; i_0 < end; ++i_0, val >>= 2) {
          if ((val & 3) != find_0) {
            continue;
          }
          symcord1 = ~~(i_0 / 20160);
          cord1 = sym2raw_0[symcord1];
          cord2 = i_0 % 20160;
          $set_4(e, cord1 * 20160 + cord2);
          for (m_0 = 0; m_0 < 17; ++m_0) {
            cord1x = getmvrot(e.edge, m_0 << 3, 4);
            symcord1x = raw2sym_1[cord1x];
            symx = symcord1x & 7;
            symcord1x >>= 3;
            cord2x = getmvrot(e.edge, m_0 << 3 | symx, 10) % 20160;
            idx = symcord1x * 20160 + cord2x;
            if (getPruning_0(eprun, idx) != chk) {
              continue;
            }
            setPruning_0(eprun, inv ? i_0 : idx, dep1m3);
            ++done_0;
            if (inv) {
              break;
            }
            symState = symstate[symcord1x];
            if (symState == 1) {
              continue;
            }
            $set_5(f, e);
            $move_4(f, m_0);
            $rotate_0(f, symx);
            for (j = 1;
              (symState = ~~symState >> 1 & 65535) != 0; ++j) {
              if ((symState & 1) != 1) {
                continue;
              }
              $set_5(g, f);
              $rotate_0(g, j);
              idxx = symcord1x * 20160 + $get_2(g, 10) % 20160;
              if (getPruning_0(eprun, idxx) == chk) {
                setPruning_0(eprun, idxx, dep1m3);
                ++done_0;
              }
            }
          }
        }
      }
      ++depth;
      // console.log(depth + '\t' + done_0 + '\t' + (+new Date - start));
    }
  }

  function getPruning_0(table, index) {
    return table[index >> 4] >> ((index & 15) << 1) & 3;
  }

  function getmvrot(ep, mrIdx, end) {
    var i_0, idx, mov, movo, v, valh, vall;
    movo = mvroto[mrIdx];
    mov = mvrot[mrIdx];
    idx = 0;
    vall = 1985229328;
    valh = 47768;
    for (i_0 = 0; i_0 < end; ++i_0) {
      v = movo[ep[mov[i_0]]] << 2;
      idx *= 12 - i_0;
      if (v >= 32) {
        idx += valh >> v - 32 & 15;
        valh -= 4368 << v - 32;
      } else {
        idx += vall >> v & 15;
        valh -= 4369;
        vall -= 286331152 << v;
      }
    }
    return idx;
  }

  function getprun(edge) {
    var cord1, cord1x, cord2, cord2x, depm3, depth, e, idx, m_0, symcord1, symcord1x, symx;
    e = new Edge3_0;
    depth = 0;
    depm3 = getPruning_0(eprun, edge);
    if (depm3 == 3) {
      return 10;
    }
    while (edge != 0) {
      depm3 == 0 ? (depm3 = 2) : --depm3;
      symcord1 = ~~(edge / 20160);
      cord1 = sym2raw_0[symcord1];
      cord2 = edge % 20160;
      $set_4(e, cord1 * 20160 + cord2);
      for (m_0 = 0; m_0 < 17; ++m_0) {
        cord1x = getmvrot(e.edge, m_0 << 3, 4);
        symcord1x = raw2sym_1[cord1x];
        symx = symcord1x & 7;
        symcord1x >>= 3;
        cord2x = getmvrot(e.edge, m_0 << 3 | symx, 10) % 20160;
        idx = symcord1x * 20160 + cord2x;
        if (getPruning_0(eprun, idx) == depm3) {
          ++depth;
          edge = idx;
          break;
        }
      }
    }
    return depth;
  }

  function getprun_0(edge, prun) {
    var depm3;
    depm3 = getPruning_0(eprun, edge);
    if (depm3 == 3) {
      return 10;
    }
    return ((0x49249249 << depm3 >> prun) & 3) + prun - 1;
    // (depm3 - prun + 16) % 3 + prun - 1;
  }

  function initMvrot() {
    var e, i_0, m_0, r;
    e = new Edge3_0;
    for (m_0 = 0; m_0 < 20; ++m_0) {
      for (r = 0; r < 8; ++r) {
        $set_4(e, 0);
        $move_4(e, m_0);
        $rotate_0(e, r);
        for (i_0 = 0; i_0 < 12; ++i_0) {
          mvrot[m_0 << 3 | r][i_0] = e.edge[i_0];
        }
        $std(e);
        for (i_0 = 0; i_0 < 12; ++i_0) {
          mvroto[m_0 << 3 | r][i_0] = e.temp[i_0];
        }
      }
    }
  }

  function initRaw2Sym() {
    var count, e, i_0, idx, j, occ;
    e = new Edge3_0;
    occ = createArray(1485);
    for (i_0 = 0; i_0 < 1485; i_0++) {
      occ[i_0] = 0;
    }
    count = 0;
    for (i_0 = 0; i_0 < 11880; ++i_0) {
      if ((occ[~~i_0 >>> 3] & 1 << (i_0 & 7)) == 0) {
        $set_4(e, i_0 * factX[8]);
        for (j = 0; j < 8; ++j) {
          idx = $get_2(e, 4);
          idx == i_0 && (symstate[count] = (symstate[count] | 1 << j) & 65535);
          occ[~~idx >> 3] = (occ[~~idx >> 3] | 1 << (idx & 7));
          raw2sym_1[idx] = count << 3 | syminv_0[j];
          $rot_1(e, 0);
          if (j % 2 == 1) {
            $rot_1(e, 1);
            $rot_1(e, 2);
          }
        }
        sym2raw_0[count++] = i_0;
      }
    }
  }

  function setPruning_0(table, index, value) {
    table[index >> 4] ^= (3 ^ value) << ((index & 15) << 1);
  }

  defineSeed(158, 1, makeCastMap([Q$Edge3]), Edge3_0);
  _.isStd = true;
  _.temp = null;
  var FullEdgeMap, done_0 = 0,
    eprun, factX, mvrot, mvroto, prunValues, raw2sym_1, sym2raw_0, syminv_0, symstate;

  function $clinit_EdgeCube() {
    $clinit_EdgeCube = nullMethod;
    EdgeColor = [
      [2, 0],
      [5, 0],
      [3, 0],
      [4, 0],
      [3, 1],
      [5, 1],
      [2, 1],
      [4, 1],
      [2, 5],
      [3, 5],
      [3, 4],
      [2, 4]
    ];
    EdgeMap = [19, 37, 46, 10, 52, 43, 25, 16, 21, 50, 48, 23, 7, 3, 1, 5, 34, 30, 28, 32, 41, 39, 14, 12];
  }

  function $checkEdge(this$static) {
    var ck, i_0, parity;
    ck = 0;
    parity = false;
    for (i_0 = 0; i_0 < 12; ++i_0) {
      ck |= 1 << this$static.ep[i_0];
      parity = parity != this$static.ep[i_0] >= 12;
    }
    ck &= ~~ck >> 12;
    return ck == 0 && !parity;
  }

  function $copy_3(this$static, c) {
    var i_0;
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this$static.ep[i_0] = c.ep[i_0];
    }
  }

  function $move_5(this$static, m_0) {
    var key;
    key = m_0 % 3;
    m_0 = ~~(m_0 / 3);
    switch (m_0) {
      case 0:
        swap(this$static.ep, 0, 1, 2, 3, key);
        swap(this$static.ep, 12, 13, 14, 15, key);
        break;
      case 1:
        swap(this$static.ep, 11, 15, 10, 19, key);
        swap(this$static.ep, 23, 3, 22, 7, key);
        break;
      case 2:
        swap(this$static.ep, 0, 11, 6, 8, key);
        swap(this$static.ep, 12, 23, 18, 20, key);
        break;
      case 3:
        swap(this$static.ep, 4, 5, 6, 7, key);
        swap(this$static.ep, 16, 17, 18, 19, key);
        break;
      case 4:
        swap(this$static.ep, 1, 20, 5, 21, key);
        swap(this$static.ep, 13, 8, 17, 9, key);
        break;
      case 5:
        swap(this$static.ep, 2, 9, 4, 10, key);
        swap(this$static.ep, 14, 21, 16, 22, key);
        break;
      case 6:
        swap(this$static.ep, 0, 1, 2, 3, key);
        swap(this$static.ep, 12, 13, 14, 15, key);
        swap(this$static.ep, 9, 22, 11, 20, key);
        break;
      case 7:
        swap(this$static.ep, 11, 15, 10, 19, key);
        swap(this$static.ep, 23, 3, 22, 7, key);
        swap(this$static.ep, 2, 16, 6, 12, key);
        break;
      case 8:
        swap(this$static.ep, 0, 11, 6, 8, key);
        swap(this$static.ep, 12, 23, 18, 20, key);
        swap(this$static.ep, 3, 19, 5, 13, key);
        break;
      case 9:
        swap(this$static.ep, 4, 5, 6, 7, key);
        swap(this$static.ep, 16, 17, 18, 19, key);
        swap(this$static.ep, 8, 23, 10, 21, key);
        break;
      case 10:
        swap(this$static.ep, 1, 20, 5, 21, key);
        swap(this$static.ep, 13, 8, 17, 9, key);
        swap(this$static.ep, 14, 0, 18, 4, key);
        break;
      case 11:
        swap(this$static.ep, 2, 9, 4, 10, key);
        swap(this$static.ep, 14, 21, 16, 22, key);
        swap(this$static.ep, 7, 15, 1, 17, key);
    }
  }

  function EdgeCube_0() {
    var i_0;
    this.ep = createArray(24);
    for (i_0 = 0; i_0 < 24; ++i_0) {
      this.ep[i_0] = i_0;
    }
  }

  function EdgeCube_1(r) {
    var i_0, m_0, t;
    EdgeCube_0.call(this);
    for (i_0 = 0; i_0 < 23; ++i_0) {
      t = i_0 + rn(24 - i_0);
      if (t != i_0) {
        m_0 = this.ep[i_0];
        this.ep[i_0] = this.ep[t];
        this.ep[t] = m_0;
      }
    }
  }

  defineSeed(159, 1, {}, EdgeCube_0, EdgeCube_1);
  var EdgeColor, EdgeMap;

  function $clinit_FullCube_0() {
    $clinit_FullCube_0 = nullMethod;
    move2rot = [35, 1, 34, 2, 4, 6, 22, 5, 19];
  }

  function $$init_3(this$static) {
    this$static.moveBuffer = createArray(60);
  }

  function $compareTo_1(this$static, c) {
    return this$static.value - c.value;
  }

  function $copy_4(this$static, c) {
    var i_0;
    $copy_3(this$static.edge, c.edge);
    $copy_1(this$static.center, c.center);
    $copy_2(this$static.corner, c.corner);
    this$static.value = c.value;
    this$static.add1 = c.add1;
    this$static.length1 = c.length1;
    this$static.length2 = c.length2;
    this$static.length3 = c.length3;
    this$static.sym = c.sym;
    for (i_0 = 0; i_0 < 60; ++i_0) {
      this$static.moveBuffer[i_0] = c.moveBuffer[i_0];
    }
    this$static.moveLength = c.moveLength;
    this$static.edgeAvail = c.edgeAvail;
    this$static.centerAvail = c.centerAvail;
    this$static.cornerAvail = c.cornerAvail;
  }

  function $getCenter(this$static) {
    while (this$static.centerAvail < this$static.moveLength) {
      $move_2(this$static.center, this$static.moveBuffer[this$static.centerAvail++]);
    }
    return this$static.center;
  }

  function $getCorner(this$static) {
    while (this$static.cornerAvail < this$static.moveLength) {
      $move_3(this$static.corner, this$static.moveBuffer[this$static.cornerAvail++] % 18);
    }
    return this$static.corner;
  }

  function $getEdge(this$static) {
    while (this$static.edgeAvail < this$static.moveLength) {
      $move_5(this$static.edge, this$static.moveBuffer[this$static.edgeAvail++]);
    }
    return this$static.edge;
  }

  function $getMoveString(this$static) {
    var finishSym, fixedMoves, i_0, idx, move, rot, sb, sym;
    fixedMoves = new Array(this$static.moveLength - (this$static.add1 ? 2 : 0));
    idx = 0;
    for (i_0 = 0; i_0 < this$static.length1; ++i_0) {
      fixedMoves[idx++] = this$static.moveBuffer[i_0];
    }
    sym = this$static.sym;
    for (i_0 = this$static.length1 + (this$static.add1 ? 2 : 0); i_0 < this$static.moveLength; ++i_0) {
      if (symmove[sym][this$static.moveBuffer[i_0]] >= 27) {
        fixedMoves[idx++] = symmove[sym][this$static.moveBuffer[i_0]] - 9;
        rot = move2rot[symmove[sym][this$static.moveBuffer[i_0]] - 27];
        sym = symmult[sym][rot];
      } else {
        fixedMoves[idx++] = symmove[sym][this$static.moveBuffer[i_0]];
      }
    }
    finishSym = symmult[syminv[sym]][getSolvedSym($getCenter(this$static))];
    sb = "";
    sym = finishSym;
    for (i_0 = idx - 1; i_0 >= 0; --i_0) {
      move = fixedMoves[i_0];
      move = ~~(move / 3) * 3 + (2 - move % 3);
      if (symmove[sym][move] >= 27) {
        sb = sb + move2str_1[symmove[sym][move] - 9] + ' ';
        rot = move2rot[symmove[sym][move] - 27];
        sym = symmult[sym][rot];
      } else {
        sb = sb + move2str_1[symmove[sym][move]] + ' ';
      }
    }
    return sb;
  }

  function $move_6(this$static, m_0) {
    this$static.moveBuffer[this$static.moveLength++] = m_0;
    return;
  }

  function FullCube_3() {
    $$init_3(this);
    this.edge = new EdgeCube_0;
    this.center = new CenterCube_0;
    this.corner = new CornerCube_0;
  }

  function FullCube_4(c) {
    FullCube_3.call(this);
    $copy_4(this, c);
  }

  function FullCube_5(r) {
    $$init_3(this);
    this.edge = new EdgeCube_1(r);
    this.center = new CenterCube_1(r);
    this.corner = new CornerCube_2(r);
  }

  defineSeed(160, 1, makeCastMap([Q$FullCube_0, Q$Comparable]), FullCube_3, FullCube_4, FullCube_5);
  _.compareTo$ = function compareTo_1(c) {
    return $compareTo_1(this, c);
  };
  _.add1 = false;
  _.center = null;
  _.centerAvail = 0;
  _.corner = null;
  _.cornerAvail = 0;
  _.edge = null;
  _.edgeAvail = 0;
  _.length1 = 0;
  _.length2 = 0;
  _.length3 = 0;
  _.moveLength = 0;
  _.sym = 0;
  _.value = 0;
  var move2rot;

  function $compare(c1, c2) {
    return c2.value - c1.value;
  }

  function $compare_0(c1, c2) {
    return $compare(c1, c2);
  }

  function FullCube$ValueComparator_0() {}

  defineSeed(161, 1, {}, FullCube$ValueComparator_0);
  _.compare = function compare(c1, c2) {
    return $compare_0(c1, c2);
  };

  function $clinit_Moves() {
    $clinit_Moves = nullMethod;
    var i_0, j;
    move2str_1 = ['U  ', 'U2 ', "U' ", 'R  ', 'R2 ', "R' ", 'F  ', 'F2 ', "F' ", 'D  ', 'D2 ', "D' ", 'L  ', 'L2 ', "L' ", 'B  ', 'B2 ', "B' ", 'Uw ', 'Uw2', "Uw'", 'Rw ', 'Rw2', "Rw'", 'Fw ', 'Fw2', "Fw'", 'Dw ', 'Dw2', "Dw'", 'Lw ', 'Lw2', "Lw'", 'Bw ', 'Bw2', "Bw'"];
    move2std = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 19, 21, 22, 23, 25, 28, 30, 31, 32, 34, 36];
    move3std = [0, 1, 2, 4, 6, 7, 8, 9, 10, 11, 13, 15, 16, 17, 19, 22, 25, 28, 31, 34, 36];
    std2move = createArray(37);
    std3move = createArray(37);
    ckmv = createArray(37, 36);
    ckmv2_0 = createArray(29, 28);
    ckmv3 = createArray(21, 20);
    skipAxis = createArray(36);
    skipAxis2 = createArray(28);
    skipAxis3 = createArray(20);
    for (i_0 = 0; i_0 < 29; ++i_0) {
      std2move[move2std[i_0]] = i_0;
    }
    for (i_0 = 0; i_0 < 21; ++i_0) {
      std3move[move3std[i_0]] = i_0;
    }
    for (i_0 = 0; i_0 < 36; ++i_0) {
      for (j = 0; j < 36; ++j) {
        ckmv[i_0][j] = ~~(i_0 / 3) == ~~(j / 3) || ~~(i_0 / 3) % 3 == ~~(j / 3) % 3 && i_0 > j;
      }
      ckmv[36][i_0] = false;
    }
    for (i_0 = 0; i_0 < 29; ++i_0) {
      for (j = 0; j < 28; ++j) {
        ckmv2_0[i_0][j] = ckmv[move2std[i_0]][move2std[j]];
      }
    }
    for (i_0 = 0; i_0 < 21; ++i_0) {
      for (j = 0; j < 20; ++j) {
        ckmv3[i_0][j] = ckmv[move3std[i_0]][move3std[j]];
      }
    }
    for (i_0 = 0; i_0 < 36; ++i_0) {
      skipAxis[i_0] = 36;
      for (j = i_0; j < 36; ++j) {
        if (!ckmv[i_0][j]) {
          skipAxis[i_0] = j - 1;
          break;
        }
      }
    }
    for (i_0 = 0; i_0 < 28; ++i_0) {
      skipAxis2[i_0] = 28;
      for (j = i_0; j < 28; ++j) {
        if (!ckmv2_0[i_0][j]) {
          skipAxis2[i_0] = j - 1;
          break;
        }
      }
    }
    for (i_0 = 0; i_0 < 20; ++i_0) {
      skipAxis3[i_0] = 20;
      for (j = i_0; j < 20; ++j) {
        if (!ckmv3[i_0][j]) {
          skipAxis3[i_0] = j - 1;
          break;
        }
      }
    }
  }

  var ckmv, ckmv2_0, ckmv3, move2std, move2str_1, move3std, skipAxis, skipAxis2, skipAxis3, std2move, std3move;

  function $doSearch(this$static) {
    var MAX_LENGTH2, MAX_LENGTH3, ct, edge, eparity, fb, fbprun, i_0, index, length_0, length12, length123, p1SolsArr, prun, rl, rlprun, s2ct, s2rl, solcube, ud, udprun;
    this$static.solution = '';
    ud = $getsym(new Center1_1($getCenter(this$static.c), 0));
    fb = $getsym(new Center1_1($getCenter(this$static.c), 1));
    rl = $getsym(new Center1_1($getCenter(this$static.c), 2));
    udprun = csprun[~~ud >> 6];
    fbprun = csprun[~~fb >> 6];
    rlprun = csprun[~~rl >> 6];
    this$static.p1SolsCnt = 0;
    this$static.arr2idx = 0;
    $clear(this$static.p1sols.heap);
    for (this$static.length1 = (udprun < fbprun ? udprun : fbprun) < rlprun ? udprun < fbprun ? udprun : fbprun : rlprun; this$static.length1 < 100; ++this$static.length1) {
      if (rlprun <= this$static.length1 && $search1(this$static, ~~rl >>> 6, rl & 63, this$static.length1, -1, 0) || udprun <= this$static.length1 && $search1(this$static, ~~ud >>> 6, ud & 63, this$static.length1, -1, 0) || fbprun <= this$static.length1 && $search1(this$static, ~~fb >>> 6, fb & 63, this$static.length1, -1, 0)) {
        break;
      }
    }
    p1SolsArr = $toArray_1(this$static.p1sols, initDim(_3Lcs_threephase_FullCube_2_classLit, makeCastMap([Q$FullCube_$1, Q$Serializable, Q$Object_$1]), Q$FullCube_0, 0, 0));

    p1SolsArr.sort(function(a, b) {
      return a.value - b.value
    });
    MAX_LENGTH2 = 9;
    do {
      OUT: for (length12 = p1SolsArr[0].value; length12 < 100; ++length12) {
          for (i_0 = 0; i_0 < p1SolsArr.length; ++i_0) {
            if (p1SolsArr[i_0].value > length12) {
              break;
            }
            if (length12 - p1SolsArr[i_0].length1 > MAX_LENGTH2) {
              continue;
            }
            $copy_4(this$static.c1, p1SolsArr[i_0]);
            $set_2(this$static.ct2, $getCenter(this$static.c1), parity_0($getEdge(this$static.c1).ep));
            s2ct = $getct(this$static.ct2);
            s2rl = $getrl(this$static.ct2);
            this$static.length1 = p1SolsArr[i_0].length1;
            this$static.length2 = length12 - p1SolsArr[i_0].length1;
            if ($search2(this$static, s2ct, s2rl, this$static.length2, 28, 0)) {
              break OUT;
            }
          }
        }
        ++MAX_LENGTH2;
    } while (length12 == 100);
    this$static.arr2.sort(function(a, b) {
      return a.value - b.value
    });
    index = 0;
    MAX_LENGTH3 = 13;
    do {
      OUT2: for (length123 = this$static.arr2[0].value; length123 < 100; ++length123) {
          for (i_0 = 0; i_0 < Math.min(this$static.arr2idx, 100); ++i_0) {
            if (this$static.arr2[i_0].value > length123) {
              break;
            }
            if (length123 - this$static.arr2[i_0].length1 - this$static.arr2[i_0].length2 > MAX_LENGTH3) {
              continue;
            }
            eparity = $set_6(this$static.e12, $getEdge(this$static.arr2[i_0]));
            $set_3(this$static.ct3, $getCenter(this$static.arr2[i_0]), eparity ^ parity_0($getCorner(this$static.arr2[i_0]).cp));
            ct = $getct_0(this$static.ct3);
            edge = $get_2(this$static.e12, 10);
            prun = getprun($getsym_0(this$static.e12));
            if (prun <= length123 - this$static.arr2[i_0].length1 - this$static.arr2[i_0].length2 && $search3(this$static, edge, ct, prun, length123 - this$static.arr2[i_0].length1 - this$static.arr2[i_0].length2, 20, 0)) {
              index = i_0;
              break OUT2;
            }
          }
        }
        ++MAX_LENGTH3;
    }
    while (length123 == 100);
    solcube = new FullCube_4(this$static.arr2[index]);
    this$static.length1 = solcube.length1;
    this$static.length2 = solcube.length2;
    length_0 = length123 - this$static.length1 - this$static.length2;
    for (i_0 = 0; i_0 < length_0; ++i_0) {
      $move_6(solcube, move3std[this$static.move3[i_0]]);
    }
    this$static.solution = $getMoveString(solcube);
  }

  function $init2_0(this$static, sym) {
    var ctp, i_0, next, s2ct, s2rl;
    $copy_4(this$static.c1, this$static.c);
    for (i_0 = 0; i_0 < this$static.length1; ++i_0) {
      $move_6(this$static.c1, this$static.move1[i_0]);
    }
    switch (finish_0[sym]) {
      case 0:
        $move_6(this$static.c1, 24);
        $move_6(this$static.c1, 35);
        this$static.move1[this$static.length1] = 24;
        this$static.move1[this$static.length1 + 1] = 35;
        this$static.add1 = true;
        sym = 19;
        break;
      case 12869:
        $move_6(this$static.c1, 18);
        $move_6(this$static.c1, 29);
        this$static.move1[this$static.length1] = 18;
        this$static.move1[this$static.length1 + 1] = 29;
        this$static.add1 = true;
        sym = 34;
        break;
      case 735470:
        this$static.add1 = false;
        sym = 0;
    }
    $set_2(this$static.ct2, $getCenter(this$static.c1), parity_0($getEdge(this$static.c1).ep));
    s2ct = $getct(this$static.ct2);
    s2rl = $getrl(this$static.ct2);
    ctp = ctprun[s2ct * 70 + s2rl];
    this$static.c1.value = ctp + this$static.length1;
    this$static.c1.length1 = this$static.length1;
    this$static.c1.add1 = this$static.add1;
    this$static.c1.sym = sym;
    ++this$static.p1SolsCnt;
    if (this$static.p1sols.heap.size < 500) {
      next = new FullCube_4(this$static.c1);
    } else {
      next = $poll(this$static.p1sols);
      next.value > this$static.c1.value && $copy_4(next, this$static.c1);
    }
    $add(this$static.p1sols, next);
    return this$static.p1SolsCnt == 10000;
  }

  function $init3(this$static) {
    var ct, eparity, i_0, prun;
    $copy_4(this$static.c2, this$static.c1);
    for (i_0 = 0; i_0 < this$static.length2; ++i_0) {
      $move_6(this$static.c2, this$static.move2[i_0]);
    }
    if (!$checkEdge($getEdge(this$static.c2))) {
      return false;
    }
    eparity = $set_6(this$static.e12, $getEdge(this$static.c2));
    $set_3(this$static.ct3, $getCenter(this$static.c2), eparity ^ parity_0($getCorner(this$static.c2).cp));
    ct = $getct_0(this$static.ct3);
    $get_2(this$static.e12, 10);
    prun = getprun($getsym_0(this$static.e12));
    !this$static.arr2[this$static.arr2idx] ? (this$static.arr2[this$static.arr2idx] = new FullCube_4(this$static.c2)) : $copy_4(this$static.arr2[this$static.arr2idx], this$static.c2);
    this$static.arr2[this$static.arr2idx].value = this$static.length1 + this$static.length2 + Math.max(prun, prun_0[ct]);
    this$static.arr2[this$static.arr2idx].length2 = this$static.length2;
    ++this$static.arr2idx;
    return this$static.arr2idx == this$static.arr2.length;
  }

  function $randomState(this$static, r) {
    init_5();
    this$static.c = new FullCube_5(r);
    $doSearch(this$static);
    return this$static.solution;
  }

  function $search1(this$static, ct, sym, maxl, lm, depth) {
    var axis, ctx, m_0, power, prun, symx;
    if (ct == 0) {
      return maxl == 0 && $init2_0(this$static, sym);
    }
    for (axis = 0; axis < 27; axis += 3) {
      if (axis == lm || axis == lm - 9 || axis == lm - 18) {
        continue;
      }
      for (power = 0; power < 3; ++power) {
        m_0 = axis + power;
        ctx = ctsmv[ct][symmove[sym][m_0]];
        prun = csprun[~~ctx >>> 6];
        if (prun >= maxl) {
          if (prun > maxl) {
            break;
          }
          continue;
        }
        symx = symmult[sym][ctx & 63];
        ctx >>>= 6;
        this$static.move1[depth] = m_0;
        if ($search1(this$static, ctx, symx, maxl - 1, axis, depth + 1)) {
          return true;
        }
      }
    }
    return false;
  }

  function $search2(this$static, ct, rl, maxl, lm, depth) {
    var ctx, m_0, prun, rlx;
    if (ct == 0 && ctprun[rl] == 0) {
      return maxl == 0 && $init3(this$static);
    }
    for (m_0 = 0; m_0 < 23; ++m_0) {
      if (ckmv2_0[lm][m_0]) {
        m_0 = skipAxis2[m_0];
        continue;
      }
      ctx = ctmv[ct][m_0];
      rlx = rlmv[rl][m_0];
      prun = ctprun[ctx * 70 + rlx];
      if (prun >= maxl) {
        prun > maxl && (m_0 = skipAxis2[m_0]);
        continue;
      }
      this$static.move2[depth] = move2std[m_0];
      if ($search2(this$static, ctx, rlx, maxl - 1, m_0, depth + 1)) {
        return true;
      }
    }
    return false;
  }

  function $search3(this$static, edge, ct, prun, maxl, lm, depth) {
    var cord1x, cord2x, ctx, edgex, m_0, prun1, prunx, symcord1x, symx;
    if (maxl == 0) {
      return edge == 0 && ct == 0;
    }
    $set_4(this$static.tempe[depth], edge);
    for (m_0 = 0; m_0 < 17; ++m_0) {
      if (ckmv3[lm][m_0]) {
        m_0 = skipAxis3[m_0];
        continue;
      }
      ctx = ctmove[ct][m_0];
      prun1 = prun_0[ctx];
      if (prun1 >= maxl) {
        prun1 > maxl && m_0 < 14 && (m_0 = skipAxis3[m_0]);
        continue;
      }
      edgex = getmvrot(this$static.tempe[depth].edge, m_0 << 3, 10);
      cord1x = ~~(edgex / 20160);
      symcord1x = raw2sym_1[cord1x];
      symx = symcord1x & 7;
      symcord1x >>= 3;
      cord2x = getmvrot(this$static.tempe[depth].edge, m_0 << 3 | symx, 10) % 20160;
      prunx = getprun_0(symcord1x * 20160 + cord2x, prun);
      if (prunx >= maxl) {
        prunx > maxl && m_0 < 14 && (m_0 = skipAxis3[m_0]);
        continue;
      }
      if ($search3(this$static, edgex, ctx, prunx, maxl - 1, m_0, depth + 1)) {
        this$static.move3[depth] = m_0;
        return true;
      }
    }
    return false;
  }

  function Search_4() {
    var i_0;
    this.p1sols = new PriorityQueue_0(new FullCube$ValueComparator_0);
    this.move1 = createArray(15);
    this.move2 = createArray(20);
    this.move3 = createArray(20);
    this.c1 = new FullCube_3;
    this.c2 = new FullCube_3;
    this.ct2 = new Center2_0;
    this.ct3 = new Center3_0;
    this.e12 = new Edge3_0;
    this.tempe = createArray(20);
    this.arr2 = createArray(100);
    for (i_0 = 0; i_0 < 20; ++i_0) {
      this.tempe[i_0] = new Edge3_0;
    }
  }

  function init_5() {
    if (inited_2) {
      return;
    }
    initSym_0();
    raw2sym = createArray(735471);
    initSym2Raw();
    createMoveTable();
    raw2sym = null;
    createPrun();
    init_3();
    init_4();
    initMvrot();
    initRaw2Sym();
    createPrun_0();
    inited_2 = true;
  }

  defineSeed(163, 1, makeCastMap([Q$Search_0]), Search_4);
  _.add1 = false;
  _.arr2idx = 0;
  _.c = null;
  _.length1 = 0;
  _.length2 = 0;
  _.p1SolsCnt = 0;
  _.solution = '';
  var inited_2 = false;

  function $clinit_Util_0() {
    $clinit_Util_0 = nullMethod;
    colorMap4to3 = [85, 68, 70, 66, 82, 76];
  }

  function parity_0(arr) {
    var i_0, j, len, parity;
    parity = 0;
    for (i_0 = 0, len = arr.length; i_0 < len; ++i_0) {
      for (j = i_0; j < len; ++j) {
        arr[i_0] > arr[j] && (parity ^= 1);
      }
    }
    return parity;
  }

  function swap(arr, a, b, c, d, key) {
    var temp;
    switch (key) {
      case 0:
        temp = arr[d];
        arr[d] = arr[c];
        arr[c] = arr[b];
        arr[b] = arr[a];
        arr[a] = temp;
        return;
      case 1:
        temp = arr[a];
        arr[a] = arr[c];
        arr[c] = temp;
        temp = arr[b];
        arr[b] = arr[d];
        arr[d] = temp;
        return;
      case 2:
        temp = arr[a];
        arr[a] = arr[b];
        arr[b] = arr[c];
        arr[c] = arr[d];
        arr[d] = temp;
        return;
    }
  }

  var colorMap4to3;

  function Class_0() {}

  function createForArray(packageName, className, seedId, componentType) {
    var clazz;
    clazz = new Class_0;
    clazz.typeName = packageName + className;
    isInstantiable(seedId != 0 ? -seedId : 0) && setClassLiteral(seedId != 0 ? -seedId : 0, clazz);
    clazz.modifiers = 4;
    clazz.superclass = Ljava_lang_Object_2_classLit;
    clazz.componentType = componentType;
    return clazz;
  }

  function createForClass(packageName, className, seedId, superclass) {
    var clazz;
    clazz = new Class_0;
    clazz.typeName = packageName + className;
    isInstantiable(seedId) && setClassLiteral(seedId, clazz);
    clazz.superclass = superclass;
    return clazz;
  }

  function getSeedFunction(clazz) {
    var func = seedTable[clazz.seedId];
    clazz = null;
    return func;
  }

  function isInstantiable(seedId) {
    return typeof seedId == 'number' && seedId > 0;
  }

  function setClassLiteral(seedId, clazz) {
    var proto;
    clazz.seedId = seedId;
    if (seedId == 2) {
      proto = String.prototype;
    } else {
      if (seedId > 0) {
        var seed = getSeedFunction(clazz);
        if (seed) {
          proto = seed.prototype;
        } else {
          seed = seedTable[seedId] = function() {};
          seed.___clazz$ = clazz;
          return;
        }
      } else {
        return;
      }
    }
    proto.___clazz$ = clazz;
  }

  _.val$outerIter = null;

  function $add(this$static, o) {
    if ($offer(this$static, o)) {
      return true;
    }
  }

  function $$init_6(this$static) {
    this$static.array = initDim(_3Ljava_lang_Object_2_classLit, makeCastMap([Q$Serializable, Q$Object_$1]), Q$Object, 0, 0);
  }

  function $add_0(this$static, o) {
    setCheck(this$static.array, this$static.size++, o);
    return true;
  }

  function $clear(this$static) {
    this$static.array = initDim(_3Ljava_lang_Object_2_classLit, makeCastMap([Q$Serializable, Q$Object_$1]), Q$Object, 0, 0);
    this$static.size = 0;
  }

  function $get_4(this$static, index) {
    return this$static.array[index];
  }

  function $remove_0(this$static, index) {
    var previous;
    previous = this$static.array[index];
    splice_0(this$static.array, index, 1);
    --this$static.size;
    return previous;
  }

  function $set_7(this$static, index, o) {
    var previous;
    previous = this$static.array[index];
    setCheck(this$static.array, index, o);
    return previous;
  }

  function $toArray_0(this$static, out) {
    var i_0;
    out.length < this$static.size && (out = createFrom(out, this$static.size));
    for (i_0 = 0; i_0 < this$static.size; ++i_0) {
      setCheck(out, i_0, this$static.array[i_0]);
    }
    out.length > this$static.size && setCheck(out, this$static.size, null);
    return out;
  }

  function ArrayList_1() {
    $$init_6(this);
    this.array.length = 500;
  }

  function splice_0(array, index, deleteCount) {
    array.splice(index, deleteCount);
  }
  _.size = 0;

  function binarySearch_0(sortedArray, key) {
    var high, low, mid, midVal;
    low = 0;
    high = sortedArray.length - 1;
    while (low <= high) {
      mid = low + (~~(high - low) >> 1);
      midVal = sortedArray[mid];
      if (midVal < key) {
        low = mid + 1;
      } else if (midVal > key) {
        high = mid - 1;
      } else {
        return mid;
      }
    }
    return -low - 1;
  }

  function fill_0(a) {
    fill_1(a, a.length);
  }

  function fill_1(a, toIndex) {
    var i_0;
    for (i_0 = 0; i_0 < toIndex; ++i_0) {
      a[i_0] = -1;
    }
  }

  function $mergeHeaps(this$static, node) {
    var heapSize, smallestChild, value, leftChild, rightChild, smallestChild_0;
    heapSize = this$static.heap.size;
    value = $get_4(this$static.heap, node);
    while (node * 2 + 1 < heapSize) {
      smallestChild = (leftChild = 2 * node + 1, rightChild = leftChild + 1, smallestChild_0 = leftChild, rightChild < heapSize && $compare_0($get_4(this$static.heap, rightChild), $get_4(this$static.heap, leftChild)) < 0 && (smallestChild_0 = rightChild), smallestChild_0);
      if ($compare_0(value, $get_4(this$static.heap, smallestChild)) < 0) {
        break;
      }
      $set_7(this$static.heap, node, $get_4(this$static.heap, smallestChild));
      node = smallestChild;
    }
    $set_7(this$static.heap, node, value);
  }

  function $offer(this$static, e) {
    var childNode, node;
    node = this$static.heap.size;
    $add_0(this$static.heap, e);
    while (node > 0) {
      childNode = node;
      node = ~~((node - 1) / 2);
      if ($compare_0($get_4(this$static.heap, node), e) <= 0) {
        $set_7(this$static.heap, childNode, e);
        return true;
      }
      $set_7(this$static.heap, childNode, $get_4(this$static.heap, node));
    }
    $set_7(this$static.heap, node, e);
    return true;
  }

  function $poll(this$static) {
    var value;
    if (this$static.heap.size == 0) {
      return null;
    }
    value = $get_4(this$static.heap, 0);
    $removeAtIndex(this$static);
    return value;
  }

  function $removeAtIndex(this$static) {
    var lastValue;
    lastValue = $remove_0(this$static.heap, this$static.heap.size - 1);
    if (0 < this$static.heap.size) {
      $set_7(this$static.heap, 0, lastValue);
      $mergeHeaps(this$static, 0);
    }
  }

  function $toArray_1(this$static, a) {
    return $toArray_0(this$static.heap, a);
  }

  function PriorityQueue_0(cmp) {
    this.heap = new ArrayList_1;
    this.cmp = cmp;
  }

  defineSeed(239, 1, {}, PriorityQueue_0);
  _.cmp = null;
  _.heap = null;

  var Ljava_lang_Object_2_classLit = createForClass('java.lang.', 'Object', 1, null),
    _3Ljava_lang_Object_2_classLit = createForArray('[Ljava.lang.', 'Object;', 356, Ljava_lang_Object_2_classLit),
    Lcs_threephase_FullCube_2_classLit = createForClass('cs.threephase.', 'FullCube', 160, Ljava_lang_Object_2_classLit),
    _3Lcs_threephase_FullCube_2_classLit = createForArray('[Lcs.threephase.', 'FullCube;', 381, Lcs_threephase_FullCube_2_classLit);

  var searcher;

  function init() {
    init = nullMethod;
    $clinit_Moves();
    $clinit_Util_0();
    $clinit_Center1();
    $clinit_Center2();
    $clinit_Center3();
    $clinit_Edge3();
    $clinit_CenterCube();
    $clinit_CornerCube();
    $clinit_EdgeCube();
    $clinit_FullCube_0();
    searcher = new Search_4();
  }

  function getRandomScramble() {
    init();
    return (scramble_333.getRandomScramble() + $randomState(searcher, Math)).replace(/\s+/g, ' ');
  }

  scrMgr.reg('444wca', getRandomScramble)

  return {
    getRandomScramble: getRandomScramble
  }

})(mathlib.rn, mathlib.Cnk, mathlib.circle);

console.log(scramble_444.getRandomScramble());
