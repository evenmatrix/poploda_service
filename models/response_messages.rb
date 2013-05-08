require "yaml"
path = File.join(File.dirname(__FILE__), '../config/response_message.yml')
RESPONSE_CODE_MESSAGES = YAML.load_file(path)
INTERSWITCH_RESPONSE_CODE_TO_MESSAGE=RESPONSE_CODE_MESSAGES['interswitch']['messages']
WALLET_RESPONSE_CODE_TO_MESSAGE=RESPONSE_CODE_MESSAGES['wallet']['messages']
WALLET_RESPONSE_CODE_TO_DESCRIPTION=RESPONSE_CODE_MESSAGES['wallet']['description']