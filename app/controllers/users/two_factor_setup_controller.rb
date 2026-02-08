class Users::TwoFactorSetupController < ApplicationController
  def show
    if current_user.two_factor_enabled?
      render :enabled
    else
      current_user.regenerate_otp_secret!
      @qr_code = generate_qr_code(current_user.otp_provisioning_uri)
      render :setup
    end
  end

  def enable
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.enable_two_factor!
      redirect_to users_two_factor_setup_path, notice: t('two_factor.enabled')
    else
      @qr_code = generate_qr_code(current_user.otp_provisioning_uri)
      flash.now[:alert] = t('two_factor.invalid_code')
      render :setup
    end
  end

  def disable
    current_user.disable_two_factor!
    redirect_to users_two_factor_setup_path, notice: t('two_factor.disabled')
  end

  private

  def generate_qr_code(uri)
    qrcode = RQRCode::QRCode.new(uri)
    qrcode.as_svg(
      offset: 0,
      color: '000',
      shape_rendering: 'crispEdges',
      module_size: 4,
      standalone: true
    )
  end
end
