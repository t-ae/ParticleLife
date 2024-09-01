# Particle Life

Particle Life for macOS/Metal.

[![Demo](https://img.youtube.com/vi/sMCg2N1tcBA/0.jpg)](https://www.youtube.com/watch?v=sMCg2N1tcBA)

## Force functions

### force1

The force function described in [the reference video](https://youtu.be/scvuli-zcRc?si=QMxci6VO3pppf4lN).

```math
force1(distance, attraction) = \left\{
\begin{array}{ll}
-1 + \frac{distance}{beta} & (distance \le beta) \\
attraction * \frac{1-|2*distance-1-beta|}{1-beta} & (beta \lt distance \le 1)
\end{array}
\right.
\\
(beta = 0.3)
```

### force2

```math
force2(distance, attraction) = \left\{
\begin{array}{ll}
-1 + \frac{attraction+1}{beta} * distance & (distance \le beta) \\
\frac{attraction}{beta-1} * (distance-1) & (beta \lt distance \le 1)
\end{array}
\right.
\\
(beta = 0.65)
```

### force3

Combination of `force1` and `force2`.

```math
force3(distance, attraction) = \left\{
\begin{array}{ll}
force1(distance, attraction) & (attraction \ge 0) \\
force2(distance, attraction) & (attraction \lt 0)
\end{array}
\right.
```

# Reference 
- https://particle-life.com/
- [The code behind Particle Life](https://youtu.be/scvuli-zcRc?si=QMxci6VO3pppf4lN)
