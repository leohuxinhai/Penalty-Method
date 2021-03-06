function [f,g,H,opt] = phi_lambda(m,D,alpha,lambda,model)
% Evaluate penalty misfit
%
% use:
%   [f,g,H] = phi_lambda(m,Q,D,lambda,model)
%
% input:
%
% output:
%
%

%%
if isfield(model,'mref')
    mref = model.mref;
else
    mref = 0*m;
end
if isfield(model,'mask')
    mask = model.mask;
else
    mask = 1;
end
%% get matrices
L = getL(model.h,model.n);
A = getA(model.f,m,model.h,model.n);
P = getP(model.h,model.n,model.zr,model.xr);
Q = getP(model.h,model.n,model.zs,model.xs);
G = @(u)getG(model.f,m,u,model.h,model.n);

ns = size(Q,2);
%% forward solve
%U = [sqrt(lambda)*A;P]\[sqrt(lambda)*P'*Q;D];
U = (lambda*(A'*A) + (P*P'))\(P*D + lambda*A'*Q);

%% adjoint field
V = lambda*(A*U - Q);

%% compute f
f = .5*norm(P'*U - D,'fro')^2 + .5*lambda*norm(A*U - Q,'fro')^2 + .5*alpha*norm(L*m)^2;

%% compute g
g = alpha*(L'*L)*m;

for k = 1:ns
    g = g + real(G(U(:,k))'*V(:,k));
end
g = mask.*g;
%% get H
H = @(x)Hmv(x,m,U,alpha,lambda,model);

%% optimality
opt = [norm(g),  norm(A'*V - P*(D - P'*U),'fro'), norm(A*U - Q,'fro'), norm(m-mref), norm((D - P'*U),'fro')];

end

function y = Hmv(x,m,U,alpha,lambda,model)
%%
ns = size(U,2);
if isfield(model,'mask')
    mask = model.mask;
else
    mask = 1;
end
%% get matrices
L = getL(model.h,model.n);
A = getA(model.f,m,model.h,model.n);
P = getP(model.h,model.n,model.zr,model.xr);
G = @(u)getG(model.f,m,u,model.h,model.n);

%% compute mat-vec
y = mask.*x;
y = alpha*(L'*L)*y;

for k = 1:ns
    y = y + real(lambda*G(U(:,k))'*G(U(:,k))*x - lambda^2*G(U(:,k))'*A*((P*P' + lambda*(A'*A))\(A'*G(U(:,k))*x)));
end
y = mask.*y;
end
