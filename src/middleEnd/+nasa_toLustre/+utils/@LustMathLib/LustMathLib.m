classdef LustMathLib
    %LustMathLib This class  is a set of Lustre math libraries.
    
    properties
    end
    
    methods(Static)
        %% Min Max
        [node, external_nodes_i, opens, abstractedNodes] = getMinMax(minOrMAx, dt)
        [node, external_nodes_i, opens, abstractedNodes] = get__min_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__min_real(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__max_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__max_real(varargin)
        %% external libraries
        [node, external_nodes_i, opens, abstractedNodes] = get_lustrec_math(lus_backend)
        [node, external_nodes_i, opens, abstractedNodes] = get_simulink_math_fcn(lus_backend)
        %% fabs, abs
        [node, external_nodes_i, opens, abstractedNodes] = get__fabs(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_abs_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_abs_real(varargin)
        %% sign
        [node, external_nodes_i, opens, abstractedNodes] = get_sign_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_sign_real(varargin)
        %% Bitwise operators
        [node, external_nodes, opens, abstractedNodes] = getBitwiseSigned(op, n)
        [node, external_nodes, opens, abstractedNodes] = getANDBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getNANDBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getNORBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getORBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getXORBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseUnsigned(n)
        [node, external_nodes, opens, abstractedNodes] = getNOTBitwiseSigned()
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__AND_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NAND_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__OR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Unsigned_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__XOR_Bitwise_Signed_32(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Signed(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_8(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_16(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__NOT_Bitwise_Unsigned_32(varargin)
        %% Integer division
        % The following functions assume "/" and "mod" in Lustre as in
        % euclidean division for integers.
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Ceiling(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Floor(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Nearest(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_int_div_Zero(varargin)
        %% fmod, rem, mod
        [node, external_nodes_i, opens, abstractedNodes] = get_fmod(lus_backend)
        [node, external_nodes_i, opens, abstractedNodes] = get_rem_int_int(varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_mod_int_int(varargin)
        %% Matrix inversion
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_2x2(lus_backend, varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_3x3(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_4x4(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_5x5(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_6x6(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get__inv_M_7x7(lus_backend,varargin)
        [node, external_nodes_i, opens, abstractedNodes] = get_inverse_code(lus_backend,n)
        body = get_Det_Adjugate_Code(n,det,a,adj)
        contractBody = getContractBody_nxn_inverstion(n,inputs,outputs)
    end
    
end

