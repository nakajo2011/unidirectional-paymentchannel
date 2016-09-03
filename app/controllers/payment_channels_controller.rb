class PaymentChannelsController < ApplicationController

  include Concerns::BitcoinWrapper

  before_action :load_channel, except: [:new]

  def new
    channel = PaymentChannel.new
    render json: {channel_id: channel.channel_id} if channel.save
  end

  # generate new public key
  def new_key
    @payment_channel.key = Key.new
    render json: {pubkey: @payment_channel.key.pubkey} if @payment_channel.save
  end

  # sign refund transaction
  def sign_refund_tx
    payload = jparams[:tx]
    redeem_script = jparams[:redeem_script].htb
    tx = Bitcoin::Protocol::Tx.new(payload.htb)
    sig_hash = tx.signature_hash_for_input(0, redeem_script)
    key = Bitcoin::Key.new
    key.priv = @payment_channel.key.privkey
    script_sig = Bitcoin::Script.to_p2sh_multisig_script_sig(redeem_script)
    script_sig = Bitcoin::Script.add_sig_to_multisig_script_sig(key.sign(sig_hash), script_sig)
    tx.inputs[0].script_sig = script_sig
    puts "script_sig = #{script_sig}"
    puts "tx = #{tx.to_payload.bth}"
    render json: {tx: tx.to_payload.bth}
  end

  private
  def load_channel
    @payment_channel = PaymentChannel.channel_id(params[:id]).first
  end

  def jparams
    @jparams ||= JSON.parse(request.body.read, {:symbolize_names => true})
  end

end