/*

scramble_sq1.js

Square-1 Solver / Scramble Generator in Javascript.

Ported from PPT, written Walter Souza: https://bitbucket.org/walter/puzzle-timer/src/7049018bbdc7/src/com/puzzletimer/solvers/Square1Solver.java
Ported by Lucas Garron, November 16, 2011.

TODO:
- Try to ini using pregenerated JSON.
- Try to optimize arrays (byte arrays?).

*/

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

(function(set8Perm, get8Perm, circle, rn) {

    function FullCube_copy(obj, c) {
        obj.ul = c.ul;
        obj.ur = c.ur;
        obj.dl = c.dl;
        obj.dr = c.dr;
        obj.ml = c.ml;
    }

    function FullCube_doMove(obj, move) {
        var temp;
        move <<= 2;
        if (move > 24) {
            move = 48 - move;
            temp = obj.ul;
            obj.ul = (obj.ul >> move | obj.ur << 24 - move) & 16777215;
            obj.ur = (obj.ur >> move | temp << 24 - move) & 16777215;
        } else if (move > 0) {
            temp = obj.ul;
            obj.ul = (obj.ul << move | obj.ur >> 24 - move) & 16777215;
            obj.ur = (obj.ur << move | temp >> 24 - move) & 16777215;
        } else if (move == 0) {
            temp = obj.ur;
            obj.ur = obj.dl;
            obj.dl = temp;
            obj.ml = 1 - obj.ml;
        } else if (move >= -24) {
            move = -move;
            temp = obj.dl;
            obj.dl = (obj.dl << move | obj.dr >> 24 - move) & 16777215;
            obj.dr = (obj.dr << move | temp >> 24 - move) & 16777215;
        } else if (move < -24) {
            move = 48 + move;
            temp = obj.dl;
            obj.dl = (obj.dl >> move | obj.dr << 24 - move) & 16777215;
            obj.dr = (obj.dr >> move | temp << 24 - move) & 16777215;
        }
    }

    function FullCube_getParity(obj) {
        var a, b, cnt, i, p;
        cnt = 0;
        obj.arr[0] = FullCube_pieceAt(obj, 0);
        for (i = 1; i < 24; ++i) {
            FullCube_pieceAt(obj, i) != obj.arr[cnt] && (obj.arr[++cnt] = FullCube_pieceAt(obj, i));
        }
        p = 0;
        for (a = 0; a < 16; ++a) {
            for (b = a + 1; b < 16; ++b) {
                obj.arr[a] > obj.arr[b] && (p ^= 1);
            }
        }
        return p;
    }

    function FullCube_getShapeIdx(obj) {
        var dlx, drx, ulx, urx;
        urx = obj.ur & 1118481;
        urx |= urx >> 3;
        urx |= urx >> 6;
        urx = urx & 15 | urx >> 12 & 48;
        ulx = obj.ul & 1118481;
        ulx |= ulx >> 3;
        ulx |= ulx >> 6;
        ulx = ulx & 15 | ulx >> 12 & 48;
        drx = obj.dr & 1118481;
        drx |= drx >> 3;
        drx |= drx >> 6;
        drx = drx & 15 | drx >> 12 & 48;
        dlx = obj.dl & 1118481;
        dlx |= dlx >> 3;
        dlx |= dlx >> 6;
        dlx = dlx & 15 | dlx >> 12 & 48;
        return Shape_getShape2Idx(FullCube_getParity(obj) << 24 | ulx << 18 | urx << 12 | dlx << 6 | drx);
    }

    function FullCube_getSquare(obj, sq) {
        var a, b;
        for (a = 0; a < 8; ++a) {
            obj.prm[a] = FullCube_pieceAt(obj, a * 3 + 1) >> 1;
        }
        sq.cornperm = get8Perm(obj.prm);
        sq.topEdgeFirst = FullCube_pieceAt(obj, 0) == FullCube_pieceAt(obj, 1);
        a = sq.topEdgeFirst ? 2 : 0;
        for (b = 0; b < 4; a += 3, ++b)
            obj.prm[b] = FullCube_pieceAt(obj, a) >> 1;
        sq.botEdgeFirst = FullCube_pieceAt(obj, 12) == FullCube_pieceAt(obj, 13);
        a = sq.botEdgeFirst ? 14 : 12;
        for (; b < 8; a += 3, ++b)
            obj.prm[b] = FullCube_pieceAt(obj, a) >> 1;
        sq.edgeperm = get8Perm(obj.prm);
        sq.ml = obj.ml;
    }

    function FullCube_pieceAt(obj, idx) {
        var ret;
        idx < 6 ? (ret = obj.ul >> (5 - idx << 2)) : idx < 12 ? (ret = obj.ur >> (11 - idx << 2)) : idx < 18 ? (ret = obj.dl >> (17 - idx << 2)) : (ret = obj.dr >> (23 - idx << 2));
        return (ret & 15);
    }

    function FullCube_setPiece(obj, idx, value) {
        if (idx < 6) {
            obj.ul &= ~(0xf << ((5 - idx) << 2));
            obj.ul |= value << ((5 - idx) << 2);
        } else if (idx < 12) {
            obj.ur &= ~(0xf << ((11 - idx) << 2));
            obj.ur |= value << ((11 - idx) << 2);
        } else if (idx < 18) {
            obj.dl &= ~(0xf << ((17 - idx) << 2));
            obj.dl |= value << ((17 - idx) << 2);
        } else {
            obj.dr &= ~(0xf << ((23 - idx) << 2));
            obj.dr |= value << ((23 - idx) << 2);
        }
    }

    function FullCube_FullCube__Ljava_lang_String_2V() {
        this.arr = [];
        this.prm = [];
    }

    function FullCube_randomEP() {
        var f, i, shape, edge, n_edge, n_corner, rnd, m;
        f = new FullCube_FullCube__Ljava_lang_String_2V;
        shape = Shape_ShapeIdx[FullCube_getShapeIdx(f) >> 1];
        edge = 0x01234567 << 1;
        n_edge = 8;
        for (i = 0; i < 24; i++) {
            if (((shape >> i) & 1) == 0) { //edge
                rnd = rn(n_edge) << 2;
                FullCube_setPiece(f, 23 - i, (edge >> rnd) & 0xf);
                m = (1 << rnd) - 1;
                edge = (edge & m) + ((edge >> 4) & ~m);
                --n_edge;
            } else {
                ++i;
            }
        }
        f.ml = rn(2);
        return f;
    }

    function FullCube_randomCube(indice) {
        var f, i, shape, edge, corner, n_edge, n_corner, rnd, m;
        if (indice === undefined) {
            indice = rn(3678);
        }
        f = new FullCube_FullCube__Ljava_lang_String_2V;
        shape = Shape_ShapeIdx[indice];
        corner = 0x01234567 << 1 | 0x11111111;
        edge = 0x01234567 << 1;
        n_corner = n_edge = 8;
        for (i = 0; i < 24; i++) {
            if (((shape >> i) & 1) == 0) { //edge
                rnd = rn(n_edge) << 2;
                FullCube_setPiece(f, 23 - i, (edge >> rnd) & 0xf);
                m = (1 << rnd) - 1;
                edge = (edge & m) + ((edge >> 4) & ~m);
                --n_edge;
            } else { //corner
                rnd = rn(n_corner) << 2;
                FullCube_setPiece(f, 23 - i, (corner >> rnd) & 0xf);
                FullCube_setPiece(f, 22 - i, (corner >> rnd) & 0xf);
                m = (1 << rnd) - 1;
                corner = (corner & m) + ((corner >> 4) & ~m);
                --n_corner;
                ++i;
            }
        }
        f.ml = rn(2);
        return f;
    }

    function FullCube() {}

    var _ = FullCube_FullCube__Ljava_lang_String_2V.prototype = FullCube.prototype;
    _.dl = 10062778;
    _.dr = 14536702;
    _.ml = 0;
    _.ul = 70195;
    _.ur = 4544119;

    function Search_init2(obj) {
        var corner, edge, i, j, ml, prun;
        FullCube_copy(obj.Search_d, obj.Search_c);
        for (i = 0; i < obj.Search_length1; ++i) {
            FullCube_doMove(obj.Search_d, obj.Search_move[i]);
        }
        FullCube_getSquare(obj.Search_d, obj.Search_sq);
        edge = obj.Search_sq.edgeperm;
        corner = obj.Search_sq.cornperm;
        ml = obj.Search_sq.ml;
        prun = Math.max(SquarePrun[obj.Search_sq.edgeperm << 1 | ml], SquarePrun[obj.Search_sq.cornperm << 1 | ml]);
        for (i = prun; i < obj.Search_maxlen2; ++i) {
            if (Search_phase2(obj, edge, corner, obj.Search_sq.topEdgeFirst, obj.Search_sq.botEdgeFirst, ml, i, obj.Search_length1, 0)) {
                for (j = 0; j < i; ++j) {
                    FullCube_doMove(obj.Search_d, obj.Search_move[obj.Search_length1 + j]);
                }
                obj.Search_sol_string = Search_move2string(obj, i + obj.Search_length1);
                return true;
            }
        }
        return false;
    }

    function Search_move2string(obj, len) {
        var s = "";
        var top = 0,
            bottom = 0;
        for (var i = len - 1; i >= 0; i--) {
            var val = obj.Search_move[i];
            //console.log(val);
            if (val > 0) {
                val = 12 - val;
                top = (val > 6) ? (val - 12) : val;
            } else if (val < 0) {
                val = 12 + val;
                bottom = (val > 6) ? (val - 12) : val;
            } else {
                var twst = "/";
                if (i == obj.Search_length1 - 1) {
                    twst = "`/`";
                }
                if (top == 0 && bottom == 0) {
                    s += twst;
                } else {
                    s += " (" + top + "," + bottom + ")" + twst;
                }
                top = bottom = 0;
            }
        }
        if (top == 0 && bottom == 0) {} else {
            s += " (" + top + "," + bottom + ") ";
        }
        return s; // + " (" + len + "t)";
    }

    function Search_phase1(obj, shape, prunvalue, maxl, depth, lm) {
        var m, prunx, shapex;
        if (prunvalue == 0 && maxl < 4) {
            return maxl == 0 && Search_init2(obj);
        }
        if (lm != 0) {
            shapex = Shape_TwistMove[shape];
            prunx = ShapePrun[shapex];
            if (prunx < maxl) {
                obj.Search_move[depth] = 0;
                if (Search_phase1(obj, shapex, prunx, maxl - 1, depth + 1, 0)) {
                    return true;
                }
            }
        }
        shapex = shape;
        if (lm <= 0) {
            m = 0;
            while (true) {
                m += Shape_TopMove[shapex];
                shapex = m >> 4;
                m &= 15;
                if (m >= 12) {
                    break;
                }
                prunx = ShapePrun[shapex];
                if (prunx > maxl) {
                    break;
                } else if (prunx < maxl) {
                    obj.Search_move[depth] = m;
                    if (Search_phase1(obj, shapex, prunx, maxl - 1, depth + 1, 1)) {
                        return true;
                    }
                }
            }
        }
        shapex = shape;
        if (lm <= 1) {
            m = 0;
            while (true) {
                m += Shape_BottomMove[shapex];
                shapex = m >> 4;
                m &= 15;
                if (m >= 6) {
                    break;
                }
                prunx = ShapePrun[shapex];
                if (prunx > maxl) {
                    break;
                } else if (prunx < maxl) {
                    obj.Search_move[depth] = -m;
                    if (Search_phase1(obj, shapex, prunx, maxl - 1, depth + 1, 2)) {
                        return true;
                    }
                }
            }
        }
        return false;
    }

    function Search_phase2(obj, edge, corner, topEdgeFirst, botEdgeFirst, ml, maxl, depth, lm) {
        var botEdgeFirstx, cornerx, edgex, m, prun1, prun2, topEdgeFirstx;
        if (maxl == 0 && !topEdgeFirst && botEdgeFirst) {
            return true;
        }
        if (lm != 0 && topEdgeFirst == botEdgeFirst) {
            edgex = Square_TwistMove[edge];
            cornerx = Square_TwistMove[corner];
            if (SquarePrun[edgex << 1 | 1 - ml] < maxl && SquarePrun[cornerx << 1 | 1 - ml] < maxl) {
                obj.Search_move[depth] = 0;
                if (Search_phase2(obj, edgex, cornerx, topEdgeFirst, botEdgeFirst, 1 - ml, maxl - 1, depth + 1, 0)) {
                    return true;
                }
            }
        }
        if (lm <= 0) {
            topEdgeFirstx = !topEdgeFirst;
            edgex = topEdgeFirstx ? Square_TopMove[edge] : edge;
            cornerx = topEdgeFirstx ? corner : Square_TopMove[corner];
            m = topEdgeFirstx ? 1 : 2;
            prun1 = SquarePrun[edgex << 1 | ml];
            prun2 = SquarePrun[cornerx << 1 | ml];
            while (m < 12 && prun1 <= maxl && prun1 <= maxl) {
                if (prun1 < maxl && prun2 < maxl) {
                    obj.Search_move[depth] = m;
                    if (Search_phase2(obj, edgex, cornerx, topEdgeFirstx, botEdgeFirst, ml, maxl - 1, depth + 1, 1)) {
                        return true;
                    }
                }
                topEdgeFirstx = !topEdgeFirstx;
                if (topEdgeFirstx) {
                    edgex = Square_TopMove[edgex];
                    prun1 = SquarePrun[edgex << 1 | ml];
                    m += 1;
                } else {
                    cornerx = Square_TopMove[cornerx];
                    prun2 = SquarePrun[cornerx << 1 | ml];
                    m += 2;
                }
            }
        }
        if (lm <= 1) {
            botEdgeFirstx = !botEdgeFirst;
            edgex = botEdgeFirstx ? Square_BottomMove[edge] : edge;
            cornerx = botEdgeFirstx ? corner : Square_BottomMove[corner];
            m = botEdgeFirstx ? 1 : 2;
            prun1 = SquarePrun[edgex << 1 | ml];
            prun2 = SquarePrun[cornerx << 1 | ml];
            while (m < (maxl > 6 ? 6 : 12) && prun1 <= maxl && prun1 <= maxl) {
                if (prun1 < maxl && prun2 < maxl) {
                    obj.Search_move[depth] = -m;
                    if (Search_phase2(obj, edgex, cornerx, topEdgeFirst, botEdgeFirstx, ml, maxl - 1, depth + 1, 2)) {
                        return true;
                    }
                }
                botEdgeFirstx = !botEdgeFirstx;
                if (botEdgeFirstx) {
                    edgex = Square_BottomMove[edgex];
                    prun1 = SquarePrun[edgex << 1 | ml];
                    m += 1;
                } else {
                    cornerx = Square_BottomMove[cornerx];
                    prun2 = SquarePrun[cornerx << 1 | ml];
                    m += 2;
                }
            }
        }
        return false;
    }

    function Search_solution(obj, c) {
        var shape;
        obj.Search_c = c;
        shape = FullCube_getShapeIdx(c);
        //console.log(shape);
        for (obj.Search_length1 = ShapePrun[shape]; obj.Search_length1 < 100; ++obj.Search_length1) {
            //console.log(obj.Search_length1);
            obj.Search_maxlen2 = Math.min(32 - obj.Search_length1, 17);
            if (Search_phase1(obj, shape, ShapePrun[shape], obj.Search_length1, 0, -1)) {
                break;
            }
        }
        return obj.Search_sol_string;
    }

    function Search_Search() {
        this.Search_move = [];
        this.Search_d = new FullCube_FullCube__Ljava_lang_String_2V;
        this.Search_sq = new Square_Square;
    }

    function Search() {}

    _ = Search_Search.prototype = Search.prototype;
    _.Search_c = null;
    _.Search_length1 = 0;
    _.Search_maxlen2 = 0;
    _.Search_sol_string = null;

    function Shape_$clinit() {
        Shape_$clinit = $.noop;
        Shape_halflayer = [0, 3, 6, 12, 15, 24, 27, 30, 48, 51, 54, 60, 63];
        Shape_ShapeIdx = [];
        ShapePrun = [];
        Shape_TopMove = [];
        Shape_BottomMove = [];
        Shape_TwistMove = [];
        Shape_init();
    }

    function Shape_bottomMove(obj) {
        var move, moveParity;
        move = 0;
        moveParity = 0;
        do {
            if ((obj.bottom & 2048) == 0) {
                move += 1;
                obj.bottom = obj.bottom << 1;
            } else {
                move += 2;
                obj.bottom = obj.bottom << 2 ^ 12291;
            }
            moveParity = 1 - moveParity;
        }
        while ((bitCount(obj.bottom & 63) & 1) != 0);
        (bitCount(obj.bottom) & 2) == 0 && (obj.Shape_parity ^= moveParity);
        return move;
    }

    function Shape_getIdx(obj) {
        var ret;
        ret = binarySearch(Shape_ShapeIdx, obj.top << 12 | obj.bottom) << 1 | obj.Shape_parity;
        return ret;
    }

    function Shape_setIdx(obj, idx) {
        obj.Shape_parity = idx & 1;
        obj.top = Shape_ShapeIdx[idx >> 1];
        obj.bottom = obj.top & 4095;
        obj.top >>= 12;
    }

    function Shape_topMove(obj) {
        var move, moveParity;
        move = 0;
        moveParity = 0;
        do {
            if ((obj.top & 2048) == 0) {
                move += 1;
                obj.top = obj.top << 1;
            } else {
                move += 2;
                obj.top = obj.top << 2 ^ 12291;
            }
            moveParity = 1 - moveParity;
        }
        while ((bitCount(obj.top & 63) & 1) != 0);
        (bitCount(obj.top) & 2) == 0 && (obj.Shape_parity ^= moveParity);
        return move;
    }

    function Shape_Shape() {}

    function Shape_getShape2Idx(shp) {
        var ret;
        ret = binarySearch(Shape_ShapeIdx, shp & 16777215) << 1 | shp >> 24;
        return ret;
    }

    function Shape_init() {
        var count, depth, dl, done, done0, dr, i, idx, m, s, ul, ur, value, p1, p3, temp;
        count = 0;
        for (i = 0; i < 28561; ++i) {
            dr = Shape_halflayer[i % 13];
            dl = Shape_halflayer[~~(i / 13) % 13];
            ur = Shape_halflayer[~~(~~(i / 13) / 13) % 13];
            ul = Shape_halflayer[~~(~~(~~(i / 13) / 13) / 13)];
            value = ul << 18 | ur << 12 | dl << 6 | dr;
            bitCount(value) == 16 && (Shape_ShapeIdx[count++] = value);
        }
        s = new Shape_Shape;
        for (i = 0; i < 7356; ++i) {
            Shape_setIdx(s, i);
            Shape_TopMove[i] = Shape_topMove(s);
            Shape_TopMove[i] |= Shape_getIdx(s) << 4;
            Shape_setIdx(s, i);
            Shape_BottomMove[i] = Shape_bottomMove(s);
            Shape_BottomMove[i] |= Shape_getIdx(s) << 4;
            Shape_setIdx(s, i);
            temp = s.top & 63;
            p1 = bitCount(temp);
            p3 = bitCount(s.bottom & 4032);
            s.Shape_parity ^= 1 & (p1 & p3) >> 1;
            s.top = s.top & 4032 | s.bottom >> 6 & 63;
            s.bottom = s.bottom & 63 | temp << 6;
            Shape_TwistMove[i] = Shape_getIdx(s);
        }
        for (i = 0; i < 7536; ++i) {
            ShapePrun[i] = -1;
        }
        ShapePrun[Shape_getShape2Idx(14378715)] = 0;
        ShapePrun[Shape_getShape2Idx(31157686)] = 0;
        ShapePrun[Shape_getShape2Idx(23967451)] = 0;
        ShapePrun[Shape_getShape2Idx(7191990)] = 0;
        done = 4;
        done0 = 0;
        depth = -1;
        while (done != done0) {
            done0 = done;
            ++depth;
            for (i = 0; i < 7536; ++i) {
                if (ShapePrun[i] == depth) {
                    m = 0;
                    idx = i;
                    do {
                        idx = Shape_TopMove[idx];
                        m += idx & 15;
                        idx >>= 4;
                        if (ShapePrun[idx] == -1) {
                            ++done;
                            ShapePrun[idx] = depth + 1;
                        }
                    }
                    while (m != 12);
                    m = 0;
                    idx = i;
                    do {
                        idx = Shape_BottomMove[idx];
                        m += idx & 15;
                        idx >>= 4;
                        if (ShapePrun[idx] == -1) {
                            ++done;
                            ShapePrun[idx] = depth + 1;
                        }
                    }
                    while (m != 12);
                    idx = Shape_TwistMove[i];
                    if (ShapePrun[idx] == -1) {
                        ++done;
                        ShapePrun[idx] = depth + 1;
                    }
                }
            }
        }
    }

    function Shape() {}

    _ = Shape_Shape.prototype = Shape.prototype;
    _.bottom = 0;
    _.Shape_parity = 0;
    _.top = 0;
    var Shape_BottomMove, Shape_ShapeIdx, ShapePrun, Shape_TopMove, Shape_TwistMove, Shape_halflayer;

    function Square_$clinit() {
        Square_$clinit = $.noop;
        SquarePrun = [];
        Square_TwistMove = [];
        Square_TopMove = [];
        Square_BottomMove = [];
        Square_init();
    }

    function Square_Square() {}

    function Square_init() {
        var check, depth, done, find, i, idx, idxx, inv, m, ml, pos;
        pos = [];
        for (i = 0; i < 40320; ++i) {
            set8Perm(pos, i);
            circle(pos, 2, 4)(pos, 3, 5);
            Square_TwistMove[i] = get8Perm(pos);
            set8Perm(pos, i);
            circle(pos, 0, 3, 2, 1);
            Square_TopMove[i] = get8Perm(pos);
            set8Perm(pos, i);
            circle(pos, 4, 7, 6, 5);
            Square_BottomMove[i] = get8Perm(pos);
        }
        for (i = 0; i < 80640; ++i) {
            SquarePrun[i] = -1;
        }
        SquarePrun[0] = 0;
        depth = 0;
        done = 1;
        while (done < 80640) {
            //console.log(done);
            inv = depth >= 11;
            find = inv ? -1 : depth;
            check = inv ? depth : -1;
            ++depth;
            OUT: for (i = 0; i < 80640; ++i) {
                if (SquarePrun[i] == find) {
                    idx = i >> 1;
                    ml = i & 1;
                    idxx = Square_TwistMove[idx] << 1 | 1 - ml;
                    if (SquarePrun[idxx] == check) {
                        ++done;
                        SquarePrun[inv ? i : idxx] = depth;
                        if (inv)
                            continue OUT;
                    }
                    idxx = idx;
                    for (m = 0; m < 4; ++m) {
                        idxx = Square_TopMove[idxx];
                        if (SquarePrun[idxx << 1 | ml] == check) {
                            ++done;
                            SquarePrun[inv ? i : idxx << 1 | ml] = depth;
                            if (inv)
                                continue OUT;
                        }
                    }
                    for (m = 0; m < 4; ++m) {
                        idxx = Square_BottomMove[idxx];
                        if (SquarePrun[idxx << 1 | ml] == check) {
                            ++done;
                            SquarePrun[inv ? i : idxx << 1 | ml] = depth;
                            if (inv)
                                continue OUT;
                        }
                    }
                }
            }
        }
    }

    function Square() {}

    _ = Square_Square.prototype = Square.prototype;
    _.botEdgeFirst = false;
    _.cornperm = 0;
    _.edgeperm = 0;
    _.ml = 0;
    _.topEdgeFirst = false;
    var Square_BottomMove, SquarePrun, Square_TopMove, Square_TwistMove;

    function bitCount(x) {
        x -= x >> 1 & 1431655765;
        x = (x >> 2 & 858993459) + (x & 858993459);
        x = (x >> 4) + x & 252645135;
        x += x >> 8;
        x += x >> 16;
        return x & 63;
    }

    function binarySearch(sortedArray, key) {
        var high, low, mid, midVal;
        low = 0;
        high = sortedArray.length - 1;
        while (low <= high) {
            mid = low + ((high - low) >> 1);
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

    // Star_x8 = [0];
    // Star_x71 = [1];
    // Star_x62 = [3];
    // Star_x44 = [18];
    // Star_x53 = [19];

    // Square_Scallop = [1004];
    // Square_rPawn = [1005];
    // Square_Shield = [1006];
    // Square_Barrel = [1007];
    // Square_rFist = [1008];
    // Square_Mushroom = [1009];
    // Square_lPawn = [1011];
    // Square_Square = [1015];
    // Square_lFist = [1016];
    // Square_Kite = [1018];

    // Kite_Scallop = [1154];
    // Kite_rPawn = [1155];
    // Kite_Shield = [1156];
    // Kite_Barrel = [1157];
    // Kite_rFist = [1158];
    // Kite_Mushroom = [1159];
    // Kite_lPawn = [1161];
    // Kite_lFist = [1166];
    // Kite_Kite = [1168];

    // Barrel_Scallop = [424];
    // Barrel_rPawn = [425];
    // Barrel_Shield = [426];
    // Barrel_Barrel = [427];
    // Barrel_rFist = [428];
    // Barrel_Mushroom = [429];
    // Barrel_lPawn = [431];
    // Barrel_lFist = [436];

    // Scallop_Scallop = [95];
    // Scallop_rPawn = [218];
    // Scallop_Shield = [341];
    // Scallop_rFist = [482];
    // Scallop_Mushroom = [528];
    // Scallop_lPawn = [632];
    // Scallop_lFist = [1050];

    // Shield_rPawn = [342];
    // Shield_Shield = [343];
    // Shield_rFist = [345];
    // Shield_Mushroom = [346];
    // Shield_lPawn = [348];
    // Shield_lFist = [353];

    // Mushroom_rPawn = [223];
    // Mushroom_rFist = [487];
    // Mushroom_Mushroom = [533];
    // Mushroom_lPawn = [535];
    // Mushroom_lFist = [1055];

    // Pawn_rPawn_rPawn = [219];
    // Pawn_rPawn_lPawn = [225];
    // Pawn_rPawn_rFist = [483];
    // Pawn_lPawn_rFist = [489];
    // Pawn_lPawn_lPawn = [639];
    // Pawn_rPawn_lFist = [1051];
    // Pawn_lPawn_lFist = [1057];

    // Fist_rFist_rFist = [486];
    // Fist_lFist_rFist = [1054];
    // Fist_lFist_lFist = [1062];

    // Pair_x6 = [6];
    // Pair_r42 = [21];
    // Pair_x411 = [34];
    // Pair_r51 = [46];
    // Pair_l42 = [59];
    // Pair_l51 = [71];
    // Pair_x33 = [144];
    // Pair_x312 = [157];
    // Pair_x321 = [182];
    // Pair_x222 = [305];

    // L_x6 = [7];
    // L_r42 = [22];
    // L_x411 = [35];
    // L_r51 = [47];
    // L_l42 = [60];
    // L_l51 = [72];
    // L_x33 = [145];
    // L_x312 = [158];
    // L_x321 = [183];
    // L_x222 = [306];

    // Line_x6 = [8];
    // Line_r42 = [23];
    // Line_x411 = [36];
    // Line_r51 = [48];
    // Line_l42 = [61];
    // Line_l51 = [73];
    // Line_x33 = [146];
    // Line_x312 = [159];
    // Line_x321 = [184];
    // Line_x222 = [307];

    var cspcases = [0, 1, 3, 18, 19, 1004, 1005, 1006, 1007, 1008, 1009, 1011, 1015, 1016, 1018, 1154, 1155, 1156, 1157, 1158, 1159, 1161, 1166, 1168, 424, 425, 426, 427, 428, 429, 431, 436, 95, 218, 341, 482, 528, 632, 1050, 342, 343, 345, 346, 348, 353, 223, 487, 533, 535, 1055, 219, 225, 483, 489, 639, 1051, 1057, 486, 1054, 1062, 6, 21, 34, 46, 59, 71, 144, 157, 182, 305, 7, 22, 35, 47, 60, 72, 145, 158, 183, 306, 8, 23, 36, 48, 61, 73, 146, 159, 184, 307];

    function CSPInit() {
        CSPInit = $.noop;
        var s = new Shape_Shape;
        for (var csp = 0; csp < cspcases.length; csp++) {
            var curCases = [cspcases[csp]];
            for (var i = 0; i < curCases.length; i++) {
                var shape = curCases[i];
                do {
                    shape = Shape_TopMove[shape << 1] >> 5;
                    if (curCases.indexOf(shape) == -1) {
                        curCases.push(shape);
                    }
                } while (shape != curCases[i]);
                do {
                    shape = Shape_BottomMove[shape << 1] >> 5;
                    if (curCases.indexOf(shape) == -1) {
                        curCases.push(shape);
                    }
                } while (shape != curCases[i]);
                Shape_setIdx(s, shape << 1);
                var tmp = s.top;
                s.top = s.bottom;
                s.bottom = tmp;
                shape = Shape_getIdx(s) >> 1;
                if (curCases.indexOf(shape) == -1) {
                    curCases.push(shape);
                }
            }
            cspcases[csp] = curCases;
        }
    }

    var cspfilter = ['Star-x8', 'Star-x71', 'Star-x62', 'Star-x44', 'Star-x53', 'Square-Scallop', 'Square-rPawn', 'Square-Shield', 'Square-Barrel', 'Square-rFist', 'Square-Mushroom', 'Square-lPawn', 'Square-Square', 'Square-lFist', 'Square-Kite', 'Kite-Scallop', 'Kite-rPawn', 'Kite-Shield', 'Kite-Barrel', 'Kite-rFist', 'Kite-Mushroom', 'Kite-lPawn', 'Kite-lFist', 'Kite-Kite', 'Barrel-Scallop', 'Barrel-rPawn', 'Barrel-Shield', 'Barrel-Barrel', 'Barrel-rFist', 'Barrel-Mushroom', 'Barrel-lPawn', 'Barrel-lFist', 'Scallop-Scallop', 'Scallop-rPawn', 'Scallop-Shield', 'Scallop-rFist', 'Scallop-Mushroom', 'Scallop-lPawn', 'Scallop-lFist', 'Shield-rPawn', 'Shield-Shield', 'Shield-rFist', 'Shield-Mushroom', 'Shield-lPawn', 'Shield-lFist', 'Mushroom-rPawn', 'Mushroom-rFist', 'Mushroom-Mushroom', 'Mushroom-lPawn', 'Mushroom-lFist', 'Pawn-rPawn-rPawn', 'Pawn-rPawn-lPawn', 'Pawn-rPawn-rFist', 'Pawn-lPawn-rFist', 'Pawn-lPawn-lPawn', 'Pawn-rPawn-lFist', 'Pawn-lPawn-lFist', 'Fist-rFist-rFist', 'Fist-lFist-rFist', 'Fist-lFist-lFist', 'Pair-x6', 'Pair-r42', 'Pair-x411', 'Pair-r51', 'Pair-l42', 'Pair-l51', 'Pair-x33', 'Pair-x312', 'Pair-x321', 'Pair-x222', 'L-x6', 'L-r42', 'L-x411', 'L-r51', 'L-l42', 'L-l51', 'L-x33', 'L-x312', 'L-x321', 'L-x222', 'Line-x6', 'Line-r42', 'Line-x411', 'Line-r51', 'Line-l42', 'Line-l51', 'Line-x33', 'Line-x312', 'Line-x321', 'Line-x222'];
    var cspprobs = [16, 16, 16, 10, 16, 24, 16, 24, 16, 24, 16, 16, 4, 24, 16, 48, 32, 48, 32, 48, 32, 32, 48, 16, 48, 32, 48, 16, 48, 32, 32, 48, 36, 48, 72, 72, 48, 48, 72, 48, 36, 72, 48, 48, 72, 32, 48, 16, 32, 48, 16, 32, 48, 48, 16, 48, 48, 36, 72, 36, 72, 96, 96, 72, 96, 72, 72, 72, 72, 24, 48, 64, 64, 48, 64, 48, 48, 48, 48, 16, 24, 32, 32, 24, 32, 24, 24, 24, 24, 8];

    var search = new Search_Search;

    function square1SolverGetRandomScramble(type, length, cases) {
        Shape_$clinit();
        Square_$clinit();
        var scrambleString = Search_solution(search, FullCube_randomCube());
        return scrambleString;
    }

    function square1CubeShapeParityScramble(type, length, cases) {
        Shape_$clinit();
        Square_$clinit();
        CSPInit();
        var idx = mathlib.rndEl(cspcases[scrMgr.fixCase(cases, cspprobs)]);
        var scrambleString = Search_solution(search, FullCube_randomCube(idx));
        return scrambleString;
    }

    scrMgr.reg('sqrs', square1SolverGetRandomScramble);
    scrMgr.reg('sqrcsp', square1CubeShapeParityScramble, [cspfilter, cspprobs]);


    return {
        initialize: $.noop,
        getRandomScramble: square1SolverGetRandomScramble
    };

})(mathlib.set8Perm, mathlib.get8Perm, mathlib.circle, mathlib.rn);
