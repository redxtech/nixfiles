import asyncio
import pulsectl_asyncio as pulsectl
import sys
import re


async def main():
    # Ensure argument is valid
    amount = sys.argv[-1]
    if len(amount) == 0:
        print('Value must be provided. Ex "+10%" "50%" "-5%"')
        sys.exit(2)
    match = re.search(r"\b\d+", amount)
    if match is None:
        print('Invalid value provided. Ex valid values "+10%" "50%" "-5%"')
        sys.exit(3)

    # Connect to PulseAudio and set volume
    with pulsectl.PulseAsync("polybar-set-volume") as pulse:
        await pulse.connect()

        # Get current volume
        inputs = await pulse.sink_input_list()
        spotify_sinks = [sink for sink in inputs if sink.name == "Spotify"]
        # FIXME: how do we know which sink to pick? sometimes there's multiple
        volume = round(spotify_sinks[-1].volume.value_flat * 100)

        # Figure out new volume
        is_negative = amount.startswith("-")
        is_positive = amount.startswith("+")
        is_relative = is_negative or is_positive
        amount = int(match.group()) * (-1 if is_negative else 1)
        new_volume = max(
            0, min(100, volume + amount if is_relative else amount)
        )

        # Set volume
        for sink in spotify_sinks:
            await pulse.volume_set_all_chans(sink, float(new_volume) / 100.0)


asyncio.run(main())
