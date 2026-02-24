// Downloads RIPE announced prefixes for AS32934 and adds them to the PBR user destination sets.

return function(api) {
        if (!api.compat || api.compat < 29) return;

        let url = 'https://stat.ripe.net/data/announced-prefixes/data.json?resource=AS32934';
        let iface = 'wg0';

        let raw = api.download(url);
        if (!raw) return;

        let data = json(raw);
        if (!data || !data.data || !data.data.prefixes) return;

        let set4 = api.nftset(iface, '4');
        let set6 = api.nftset(iface, '6');

        let prefixes4 = [];
        let prefixes6 = [];

        for (let entry in data.data.prefixes) {
                if (!entry.prefix) continue;

                if (index(entry.prefix, ':') < 0)
                        push(prefixes4, entry.prefix);
                else
                        push(prefixes6, entry.prefix);
        }

        for (let prefix in prefixes4)
                api.nft4('add element ' + api.table + ' ' + set4 + ' { ' + prefix + ' }');

        for (let prefix in prefixes6)
                api.nft6('add element ' + api.table + ' ' + set6 + ' { ' + prefix + ' }');
};
