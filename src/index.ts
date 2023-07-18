function echo(msg: string): string {
  return msg;
}

const str = echo("hogehoge");
document.querySelector("div")!.textContent = str;
