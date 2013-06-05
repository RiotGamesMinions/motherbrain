module MotherBrain
  module ApiValidators
    # Coerce a URI friendly version string into a SemVer string
    #
    # @example coercing a URI friendly string into a SemVer string
    #
    #   "1_0_0" => "1.0.0"
    class SemVer < Grape::Validations::Validator
      def validate_param!(attr_name, params)
        return nil if params[attr_name].nil?

        ver_string = params[attr_name].gsub('_', '.')
        Solve::Version.split(ver_string)
        params[attr_name] = ver_string
      rescue Solve::Errors::InvalidVersionFormat => ex
        throw :error, status: 400, message: ex.to_s
      end
    end
  end
end
