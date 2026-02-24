// Downloads Telegram CIDR list and adds them to the PBR user destination sets.

return function(api) {
        if (!api.compat || api.compat < 29) return;

        let url = 'https://gitlab.com/fernvenue/telegram-cidr-list/-/raw/master/CIDR.txt';
        let iface = 'wg0';

        let raw = api.download(url);
        if (!raw) return;

        let set4 = api.nftset(iface, '4');
        let set6 = api.nftset(iface, '6');

        let prefixes4 = [];
        let prefixes6 = [];

        let lines = split(raw, '\n');

        for (let line in lines) {
                line = trim(line);
                if (!line) continue;

                if (index(line, ':') < 0)
                        push(prefixes4, line);
                else
                        push(prefixes6, line);
        }

        for (let prefix in prefixes4)
                api.nft4('add element ' + api.table + ' ' + set4 + ' { ' + prefix + ' }');

        for (let prefix in prefixes6)
                api.nft6('add element ' + api.table + ' ' + set6 + ' { ' + prefix + ' }');
};
