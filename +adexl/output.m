classdef output < matlab.mixin.SetGet & matlab.mixin.Copyable
    %output An Adexl output
    %   Detailed explanation goes here
    
    properties
        Name
        Type
        Details % signal identifier or expression
        EvalType
        PlotEn
        SaveEn
        Specification
        Weight
        Units
        Domain
    end
    
    methods
        function obj = output(varargin)
            p = inputParser;
            p.addOptional('Name','',@ischar);
            p.addParameter('Details','',@ischar);
            p.addParameter('Type','',@(x) any(validatestring(x,{'expr','signal'})));
            p.addParameter('EvalType','point',@(x) any(validatestring(x,{'point','corners'})));
            p.addParameter('PlotEn',false,@islogical);
            p.addParameter('SaveEn',true,@islogical);
            p.addParameter('Spec',[],@isnumeric);
            p.addParameter('Weight','',@ischar);
            p.addParameter('Units','',@ischar);
            p.addParameter('Domain','',@ischar);
            p.parse(varargin{:});
            
            obj.Name = p.Results.Name;
            obj.Type = p.Results.Type;
            obj.Details = p.Results.Details;
            obj.EvalType = p.Results.EvalType;
            obj.PlotEn = p.Results.PlotEn;
            obj.SaveEn = p.Results.SaveEn;
            obj.Specification = p.Results.Spec;
            obj.Weight = p.Results.Weight;
            obj.Units = p.Results.Units;
        end
        function ocn = ocean(obj)
        %ocean Creates a set of ocean commands to create the test
        %   Returns a cell array of ocean commands for creating the test
        %   output(s)
        %
        % USAGE
        %  ocn = h.ocean;
        %   where h is an output handle or array of handles and ocn is a
        %   cell string.
        %   
        % See Also: adexl.output
            if(length(obj) == 1)
                switch obj.Type
                    case 'expr'
                        ocn = ['ocnxlOutputExpr( "' obj.Details '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                    case {'signal','net'}
                        if(strcmp(obj.Domain,'VOLTAGE'))
                            ocn = ['ocnxlOutputSignal( "' obj.Details '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                        else
                            ocn = ['ocnxlOutputTerminal( "' obj.Details '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                        end
                    otherwise
                        ocn = '';
                end
            else
                ocn = arrayfun(@(out) out.ocean,obj,'UniformOutput',false)';
            end
        end
        function skl = skill(obj,testName)
        %ocean Creates a set of skill commands to create the test
        %   Returns a cell array of skill commands for creating the test
        %   output(s)
        %
        % USAGE
        %  skl = h.skill(testName);
        %   where h is an output handle or array of handles and skl is a
        %   cell string.
        %   
        % See Also: adexl.output
            if(length(obj) == 1)
                switch obj.Type
                    case 'expr'
                        skl = ['axlAddOutputExpr(axlSession "' testName '" "' obj.Name '" ?expr "' obj.Details '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                    case {'signal','net','terminal'}
                        if(strcmp(obj.Domain,'VOLTAGE'))
                            skl = ['axlAddOutputSignal(axlSession "' testName '" "' obj.Details '" ?type "net" ?outputName "' obj.Name '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                        else
                            skl = ['axlAddOutputSignal(axlSession "' testName '" "' obj.Details '" ?type "terminal" ?outputName "' obj.Name '" ?plot ' cdsSkill.sklLogical(obj.PlotEn) ' ?save ' cdsSkill.sklLogical(obj.SaveEn) ')'];
                        end
                    otherwise
                        skl = '';
                end
            else
                skl = arrayfun(@(out) out.skill(testName),obj,'UniformOutput',false)';
            end
        end
    end
    methods (Static)
        
    end
    
end

