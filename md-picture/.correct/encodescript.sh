echo '#!/usr/bin/env bash' > $1b64.sh
echo "bash <(echo '$(base64 $1)' | base64 -d)" >> $1b64.sh
chmod +x $1b64.sh
mv $1b64.sh $1
